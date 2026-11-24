import 'package:data/data.dart';
import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:model/model.dart';

import '../../database/app_database.dart';
import '../../database/dao/feed_dao.dart';
import '../../database/dao/local_library_dao.dart';
import '../../database/table/local_library.dart';

/// 一次订阅 Feed 加载的汇总。
@immutable
final class const FeedLoadResult({
  /// 本次新落库的条目数（已存在的条目不算）。
  final int newEntryCount = 0,

  /// 加载结束后该数据源下未读条目总数。
  final int unreadCount = 0,

  /// 拉取失败的频道 id；非空表示这次加载不完整，下次可重试。
  final List<String> failedChannelIds = const [],
}) {
  bool get isComplete => failedChannelIds.isEmpty;
}

/// 订阅 Feed 的增量加载。
///
/// 逐订阅频道拉第一页投稿与专栏文章，遇到已落库的条目即停止翻页，只把新
/// 条目追加落库。两种能力都是可选的：来源只提供其中一种时照常加载，两种都
/// 没有时加载为空。单种能力失败只影响该频道的该种条目，另一种仍会落库。
///
/// 单频道请求数受 [loadIncremental] 的 `maxPagesPerChannel` 约束：两种能力
/// 都存在时按各自至少一页、总数不超过预算分配。一次加载中途失败时，已为
/// 该能力写入的条目会回滚，避免半页数据被下次加载误当成同步边界。
class FeedRepository({
  required final FeedDao _feedDao,
  required final LocalLibraryDao _libraryDao,
  final UserVideosRemoteDataSource? videoDataSource,
  final UserArticlesRemoteDataSource? articleDataSource,
  final int pageSize = 30,
}) {
  final UserVideosRemoteDataSource? _videoDataSource = videoDataSource;
  final UserArticlesRemoteDataSource? _articleDataSource = articleDataSource;

  /// 逐频道增量加载 [sourceId] 下的订阅投稿与专栏文章。
  ///
  /// [maxPagesPerChannel] 限制单频道最多翻几页，避免首次订阅大量历史条目时
  /// 在启动路径上打出长串请求。
  Future<FeedLoadResult> loadIncremental({
    required String sourceId,
    int maxPagesPerChannel = 3,
  }) async {
    final videos = _videoDataSource;
    final articles = _articleDataSource;
    if (videos == null && articles == null) return const FeedLoadResult();

    final subscriptions = await _libraryDao.getSubscriptions();
    var newEntryCount = 0;
    final failedChannelIds = <String>{};
    for (final subscription in subscriptions) {
      if (subscription.sourceId != sourceId) continue;
      try {
        final result = await _loadChannel(
          sourceId: sourceId,
          subscription: subscription,
          videos: videos,
          articles: articles,
          maxPagesPerChannel: maxPagesPerChannel,
        );
        newEntryCount += result.added;
        if (result.failed) failedChannelIds.add(subscription.originalId);
      } on Object {
        // 渠道级读写失败（例如本地库异常）只标记该频道，不拖停后续订阅。
        failedChannelIds.add(subscription.originalId);
      }
    }

    return FeedLoadResult(
      newEntryCount: newEntryCount,
      unreadCount: await _feedDao.getUnreadCountForSource(sourceId),
      failedChannelIds: List.unmodifiable(failedChannelIds),
    );
  }

  /// 加载单个频道，返回本次新增的条目数，以及是否有任一能力拉取失败。
  Future<({int added, bool failed})> _loadChannel({
    required String sourceId,
    required LocalSubscriptionEntity subscription,
    required UserVideosRemoteDataSource? videos,
    required UserArticlesRemoteDataSource? articles,
    required int maxPagesPerChannel,
  }) async {
    final channelId = subscription.originalId;
    final known = await _feedDao.getEntryIds(
      sourceId: sourceId,
      channelId: channelId,
    );
    var added = 0;
    var failed = false;

    // One shared request budget per channel; when both capabilities exist each
    // keeps at least one page. Videos take the odd page because they are the
    // primary feed content.
    final capabilityCount =
        (videos == null ? 0 : 1) + (articles == null ? 0 : 1);
    final totalPageBudget = maxPagesPerChannel < capabilityCount
        ? capabilityCount
        : maxPagesPerChannel;
    var videoPageBudget = 0;
    var articlePageBudget = 0;
    if (videos != null && articles != null) {
      videoPageBudget = totalPageBudget - totalPageBudget ~/ 2;
      articlePageBudget = totalPageBudget ~/ 2;
    } else if (videos != null) {
      videoPageBudget = totalPageBudget;
    } else if (articles != null) {
      articlePageBudget = totalPageBudget;
    }

    Future<void> load<T>({
      required Future<Result<Page<T>, Exception>> Function(int page) fetch,
      required String Function(T item) idOf,
      required FeedEntryCompanion Function(T item) companionOf,
      required int maxPages,
    }) async {
      try {
        added += await _loadPaged<T>(
          sourceId: sourceId,
          channelId: channelId,
          known: known,
          fetch: fetch,
          idOf: idOf,
          companionOf: companionOf,
          maxPages: maxPages,
        );
      } on Object {
        failed = true;
      }
    }

    if (videos case final videos? when videoPageBudget > 0) {
      await load<VideoModel>(
        fetch: (page) => videos.fetchUserVideos(
          channelId: channelId,
          page: page,
          pageSize: pageSize,
        ),
        idOf: (video) => video.id,
        companionOf: (video) =>
            _videoCompanion(sourceId, channelId, subscription.name, video),
        maxPages: videoPageBudget,
      );
    }
    if (articles case final articles? when articlePageBudget > 0) {
      await load<ArticleModel>(
        fetch: (page) => articles.fetchUserArticles(
          channelId: channelId,
          page: page,
          pageSize: pageSize,
        ),
        idOf: (article) => article.id,
        companionOf: (article) =>
            _articleCompanion(sourceId, channelId, subscription.name, article),
        maxPages: articlePageBudget,
      );
    }

    return (added: added, failed: failed);
  }

  /// 翻页直到追上 [known] 里的边界或达到 [maxPages]。
  ///
  /// 失败时回滚本次已写入的条目：半截数据一旦留下，下次加载会把整页都
  /// 已知误判成「已追平」，失败的后续页就再也不会被重试。
  Future<int> _loadPaged<T>({
    required String sourceId,
    required String channelId,
    required Set<String> known,
    required Future<Result<Page<T>, Exception>> Function(int page) fetch,
    required String Function(T item) idOf,
    required FeedEntryCompanion Function(T item) companionOf,
    required int maxPages,
  }) async {
    final insertedIds = <String>[];
    try {
      for (var page = 1; page <= maxPages; page++) {
        final result = await fetch(page);
        final (items, totalPages) = switch (result) {
          Success(:final success) => (success.data, success.totalPages),
          Error(:final error) => throw error,
        };
        if (items.isEmpty) break;

        final fresh = [
          for (final item in items)
            if (!known.contains(idOf(item))) item,
        ];
        // 整页都已在库里：说明已经追上上次加载的边界，停止翻页。
        if (fresh.isEmpty) break;

        await _feedDao.upsertEntries([
          for (final item in fresh) companionOf(item),
        ]);
        final freshIds = [for (final item in fresh) idOf(item)];
        insertedIds.addAll(freshIds);
        known.addAll(freshIds);

        // 本页与库内已有条目相交，说明边界已到，后面的页只会更旧。
        if (fresh.length < items.length) break;
        if (page >= totalPages) break;
      }
    } on Object {
      await _feedDao.deleteEntries(
        sourceId: sourceId,
        channelId: channelId,
        entryIds: insertedIds,
      );
      rethrow;
    }
    return insertedIds.length;
  }

  FeedEntryCompanion _videoCompanion(
    String sourceId,
    String channelId,
    String channelName,
    VideoModel video,
  ) => FeedEntryCompanion.insert(
    sourceId: sourceId,
    channelId: channelId,
    entryId: video.id,
    entryType: FeedEntry.typeVideo,
    title: video.title,
    url: video.url,
    thumbnailUrl: Value(video.thumbnailUrl),
    creatorProfileId: Value(video.creatorProfileId ?? channelId),
    creatorProfileName: Value(video.creatorProfileName ?? channelName),
    publishedAt: Value(video.uploadDate),
  );

  FeedEntryCompanion _articleCompanion(
    String sourceId,
    String channelId,
    String channelName,
    ArticleModel article,
  ) => FeedEntryCompanion.insert(
    sourceId: sourceId,
    channelId: channelId,
    entryId: article.id,
    entryType: FeedEntry.typeArticle,
    title: article.title,
    url: article.url,
    thumbnailUrl: Value(article.thumbnailUrl),
    creatorProfileId: Value(article.creatorProfileId ?? channelId),
    creatorProfileName: Value(article.creatorProfileName ?? channelName),
    publishedAt: Value(article.publishedAt),
  );
}

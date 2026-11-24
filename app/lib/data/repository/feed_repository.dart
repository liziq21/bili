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
      final result = await _loadChannel(
        sourceId: sourceId,
        subscription: subscription,
        videos: videos,
        articles: articles,
        maxPagesPerChannel: maxPagesPerChannel,
      );
      newEntryCount += result.added;
      if (result.failed) failedChannelIds.add(subscription.originalId);
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

    Future<void> load<T>({
      required Future<Result<Page<T>, Exception>> Function(int page) fetch,
      required String Function(T item) idOf,
      required FeedEntryCompanion Function(T item) companionOf,
    }) async {
      try {
        added += await _loadPaged<T>(
          known: known,
          fetch: fetch,
          idOf: idOf,
          companionOf: companionOf,
          maxPagesPerChannel: maxPagesPerChannel,
        );
      } on Object {
        failed = true;
      }
    }

    if (videos case final videos?) {
      await load<VideoModel>(
        fetch: (page) => videos.fetchUserVideos(
          channelId: channelId,
          page: page,
          pageSize: pageSize,
        ),
        idOf: (video) => video.id,
        companionOf: (video) =>
            _videoCompanion(sourceId, channelId, subscription.name, video),
      );
    }
    if (articles case final articles?) {
      await load<ArticleModel>(
        fetch: (page) => articles.fetchUserArticles(
          channelId: channelId,
          page: page,
          pageSize: pageSize,
        ),
        idOf: (article) => article.id,
        companionOf: (article) =>
            _articleCompanion(sourceId, channelId, subscription.name, article),
      );
    }

    return (added: added, failed: failed);
  }

  /// 翻页直到追上 [known] 里的边界或达到 [maxPagesPerChannel]。
  Future<int> _loadPaged<T>({
    required Set<String> known,
    required Future<Result<Page<T>, Exception>> Function(int page) fetch,
    required String Function(T item) idOf,
    required FeedEntryCompanion Function(T item) companionOf,
    required int maxPagesPerChannel,
  }) async {
    var added = 0;

    for (var page = 1; page <= maxPagesPerChannel; page++) {
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
      added += fresh.length;
      known.addAll([for (final item in fresh) idOf(item)]);

      // 本页与库内已有条目相交，说明边界已到，后面的页只会更旧。
      if (fresh.length < items.length) break;
      if (page >= totalPages) break;
    }
    return added;
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

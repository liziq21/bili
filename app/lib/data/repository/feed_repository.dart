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
/// 逐订阅频道拉第一页投稿，遇到已落库的条目即停止翻页，只把新条目追加落库。
/// 依赖可选的 [UserVideosRemoteDataSource]：当前数据源不支持频道投稿时加载为空。
class FeedRepository({
  required final FeedDao _feedDao,
  required final LocalLibraryDao _libraryDao,
  final UserVideosRemoteDataSource? _remoteDataSource,
  final int pageSize = 30,
}) {
  /// 逐频道增量加载 [sourceId] 下的订阅投稿。
  ///
  /// [maxPagesPerChannel] 限制单频道最多翻几页，避免首次订阅大量历史投稿时
  /// 在启动路径上打出长串请求。
  Future<FeedLoadResult> loadIncremental({
    required String sourceId,
    int maxPagesPerChannel = 3,
  }) async {
    final remote = _remoteDataSource;
    if (remote == null) return const FeedLoadResult();

    final subscriptions = await _libraryDao.getSubscriptions();
    var newEntryCount = 0;
    final failedChannelIds = <String>[];
    for (final subscription in subscriptions) {
      if (subscription.sourceId != sourceId) continue;
      try {
        newEntryCount += await _loadChannel(
          sourceId: sourceId,
          subscription: subscription,
          remote: remote,
          maxPagesPerChannel: maxPagesPerChannel,
        );
      } on Object {
        failedChannelIds.add(subscription.originalId);
      }
    }

    return FeedLoadResult(
      newEntryCount: newEntryCount,
      unreadCount: await _feedDao.getUnreadCountForSource(sourceId),
      failedChannelIds: List.unmodifiable(failedChannelIds),
    );
  }

  /// 加载单个频道，返回本次新增的条目数。
  Future<int> _loadChannel({
    required String sourceId,
    required LocalSubscriptionEntity subscription,
    required UserVideosRemoteDataSource remote,
    required int maxPagesPerChannel,
  }) async {
    final channelId = subscription.originalId;
    final known = await _feedDao.getEntryIds(
      sourceId: sourceId,
      channelId: channelId,
    );
    var added = 0;

    for (var page = 1; page <= maxPagesPerChannel; page++) {
      final result = await remote.fetchUserVideos(
        channelId: channelId,
        page: page,
        pageSize: pageSize,
      );
      final (videos, totalPages) = switch (result) {
        Success(:final success) => (success.data, success.totalPages),
        Error(:final error) => throw error,
      };
      if (videos.isEmpty) break;

      final fresh = [
        for (final video in videos)
          if (!known.contains(video.id)) video,
      ];
      // 整页都已在库里：说明已经追上上次加载的边界，停止翻页。
      if (fresh.isEmpty) break;

      await _feedDao.upsertEntries([
        for (final video in fresh)
          _companion(sourceId, channelId, subscription.name, video),
      ]);
      added += fresh.length;
      known.addAll([for (final video in fresh) video.id]);

      // 本页与库内已有条目相交，说明边界已到，后面的页只会更旧。
      if (fresh.length < videos.length) break;
      if (page >= totalPages) break;
    }
    return added;
  }

  FeedEntryCompanion _companion(
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
}

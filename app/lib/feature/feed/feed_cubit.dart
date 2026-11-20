import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../database/app_database.dart';
import '../../database/dao/feed_dao.dart';
import '../../database/dao/local_library_dao.dart';
import '../../domain/feed_load_manager.dart';

import 'feed_state.dart';

export 'feed_state.dart';

/// 订阅动态页的数据源：把已落库的 `feed_entry` 按频道分组。
///
/// 条目只来自本地库，网络拉取由 [FeedLoadManager] 负责（启动与下拉刷新各一次）。
/// 两个 Drift 查询流合流后重算分组，因此新条目落库、标记已读、退订都会让页面
/// 自己更新，不需要页面手动刷新。
class FeedCubit({
  required final FeedDao feedDao,
  required final LocalLibraryDao libraryDao,
  required final String sourceId,
  final FeedLoadManager? feedLoadManager,
}) extends Cubit<FeedState> {
  this
    : _feedDao = feedDao,
      _libraryDao = libraryDao,
      _sourceId = sourceId,
      _feedLoadManager = feedLoadManager,
      super(const FeedState()) {
    _watch();
  }

  final FeedDao _feedDao;
  final LocalLibraryDao _libraryDao;
  final String _sourceId;
  final FeedLoadManager? _feedLoadManager;
  final _log = Logger('FeedCubit');

  // 订阅在 [close] 中取消，生命周期与 cubit 相同。
  // ignore: cancel_subscriptions
  StreamSubscription<void>? _subscription;
  bool _isClosing = false;

  /// 合流后重算分组，而不是各自增量维护：两个流谁先到都不影响结果。
  void _watch() {
    _subscription = _feedDao
        .watchEntries(sourceId: _sourceId)
        .combineLatest(
          _libraryDao.watchSubscriptions(),
          (entries, subscriptions) => (entries, subscriptions),
        )
        .listen(
          (snapshot) => _emitGroups(snapshot.$1, snapshot.$2),
          onError: (Object error, StackTrace stackTrace) {
            if (_isClosing || isClosed) return;
            _log.warning(
              'Failed to watch subscription feed',
              error,
              stackTrace,
            );
            emit(FeedState(isLoading: false, error: error));
          },
        );
  }

  void _emitGroups(
    List<FeedEntryEntity> entries,
    List<LocalSubscriptionEntity> subscriptions,
  ) {
    if (_isClosing || isClosed) return;

    final names = {
      for (final subscription in subscriptions)
        if (subscription.sourceId == _sourceId)
          subscription.originalId: subscription,
    };

    final grouped = <String, List<FeedEntryEntity>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.channelId, () => []).add(entry);
    }

    final groups =
        [
          for (final MapEntry(key: channelId, value: channelEntries)
              in grouped.entries)
            FeedChannelGroup(
              channelId: channelId,
              channelName:
                  names[channelId]?.name ??
                  channelEntries.first.creatorProfileName ??
                  channelId,
              thumbnailUrl: names[channelId]?.thumbnailUrl,
              entries: List.unmodifiable(channelEntries),
              unreadCount: channelEntries.where((e) => !e.isRead).length,
            ),
        ]..sort((a, b) {
          final order = switch ((
            a.entries.first.publishedAt,
            b.entries.first.publishedAt,
          )) {
            (final DateTime aTime, final DateTime bTime) => bTime.compareTo(
              aTime,
            ),
            (final DateTime _, null) => -1,
            (null, final DateTime _) => 1,
            (null, null) => 0,
          };
          return order == 0 ? a.channelName.compareTo(b.channelName) : order;
        });

    emit(
      state.copyWith(
        isLoading: false,
        clearError: true,
        groups: List.unmodifiable(groups),
      ),
    );
  }

  /// 拉取一次订阅增量。失败不回滚已展示的分组：本地条目仍然有效。
  Future<void> refresh() async {
    final manager = _feedLoadManager;
    if (manager == null) return;
    try {
      await manager.load(sourceId: _sourceId);
    } on Object catch (error, stackTrace) {
      _log.warning('Failed to refresh subscription feed', error, stackTrace);
    }
  }

  void toggleChannel(String channelId) {
    final collapsed = {...state.collapsedChannelIds};
    if (!collapsed.remove(channelId)) collapsed.add(channelId);
    emit(state.copyWith(collapsedChannelIds: collapsed));
  }

  Future<void> markEntryRead(String channelId, String entryId) =>
      _feedDao.markAsRead(_sourceId, channelId, entryId);

  Future<void> markChannelRead(String channelId) =>
      _feedDao.markAllRead(_sourceId, channelId);

  @override
  Future<void> close() async {
    _isClosing = true;
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    return super.close();
  }
}

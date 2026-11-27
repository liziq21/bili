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
/// 条目只来自本地库，网络拉取由 [FeedLoadManager] 在进入页面、分支重新可见、
/// 下拉刷新与应用栏刷新时完成。两个 Drift 查询流合流后重算分组，因此新条目
/// 落库、标记已读、退订都会让页面自己更新，不需要页面手动刷新。
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
    // 进入订阅动态页即拉一次增量：桌面端没有下拉手势入口，只靠启动时
    // 的一次拉取会让新关注频道的投稿一直空着。FeedLoadManager 对并发触发
    // 去重，与启动加载撞在一起也不会重复请求。
    unawaited(refresh());
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
  bool _isRefreshing = false;
  bool _refreshFailed = false;

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

    final keepRefreshError = _refreshFailed && groups.isEmpty;
    emit(
      state.copyWith(
        // 空 feed 在远端加载结束前保持 loading；已有缓存时直接展示缓存。
        isLoading: _isRefreshing && groups.isEmpty,
        // 空 feed 的刷新失败要留在 state 里，不能被后续本地快照清掉。
        clearError: !keepRefreshError,
        groups: List.unmodifiable(groups),
      ),
    );
  }

  /// 拉取一次订阅增量。失败不回滚已展示的分组：本地条目仍然有效。
  ///
  /// 空 feed 的加载失败会写入 [FeedState.error]，让页面显示失败态而不是
  /// 误导性的「暂无更新」；已有缓存时只记日志，不把内容替换成错误页。
  Future<void> refresh() async {
    final manager = _feedLoadManager;
    if (manager == null || _isRefreshing) return;
    _isRefreshing = true;
    _refreshFailed = false;
    if (state.groups.isEmpty) {
      emit(state.copyWith(isLoading: true, clearError: true));
    }
    try {
      await manager.load(sourceId: _sourceId);
    } on Object catch (error, stackTrace) {
      _isRefreshing = false;
      _refreshFailed = true;
      _log.warning('Failed to refresh subscription feed', error, stackTrace);
      if (_isClosing || isClosed) return;
      if (state.groups.isEmpty) {
        emit(FeedState(isLoading: false, error: error));
      }
      return;
    }
    _isRefreshing = false;
    _refreshFailed = false;
    if (_isClosing || isClosed) return;
    if (state.isLoading || state.hasError) {
      emit(state.copyWith(isLoading: false, clearError: true));
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

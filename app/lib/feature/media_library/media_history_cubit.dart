import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:data/data.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../database/app_database.dart';
import '../../database/dao/media_history_dao.dart';
import '../../database/table/media.dart';

part 'media_history_state.dart';

/// 一条观看历史
///
/// 数据源跟着条目走而不是由 id 反查：`media` 表的唯一键是
/// `{sourceId, type, originalId}`（`database/table/media.dart`），同一个
/// `originalId` 在两个数据源下可以各存一行，用 id 索引的映射会让后载入的那条
/// 覆盖前一条，点开就会跳到错的服务。
///
/// [viewedAt] 是 `media_history.accessedAt`，而播放进度和完成状态由
/// [MediaHistoryState.progressByMedia] 关联提供。
typedef MediaHistoryItem = ({
  VideoModel video,
  String sourceId,
  DateTime viewedAt,
});

/// A source-scoped key for a history item's progress.
typedef MediaHistoryProgressKey = ({String sourceId, String originalId});

/// 观看历史加载器
///
/// Loads and watches the source-scoped local watch history.
///
/// The database keeps one history row per media item. Saving progress updates
/// that row and its access time, so an item can move to the front without
/// creating duplicate rows.
class MediaHistoryCubit({
  required final MediaHistoryDao mediaHistoryDao,
  final int pageSize = 20,
}) extends Cubit<MediaHistoryState> {
  this
    : _mediaHistoryDao = mediaHistoryDao,
      _pageSize = pageSize,
      super(const MediaHistoryState()) {
    loadMore();
  }

  final MediaHistoryDao _mediaHistoryDao;

  // The subscription is canceled by [_stopWatching] and [close].
  // ignore: cancel_subscriptions
  StreamSubscription<List<MediaHistoryWithMedia>>? _historySubscription;

  /// Invalidates callbacks from a query that was replaced by a new window.
  int _watchGeneration = 0;

  bool _isClosing = false;

  /// 单页条数
  final int _pageSize;

  /// 已消费的 DAO 行数（含被过滤的非视频行），下一页的 offset 基准
  ///
  /// 不能用 `state.items.length`：DAO 的 offset 按 `media_history` 行计数，而列表
  /// 里只有视频，两者不等时下一页会重复读到已消费的行。
  int _rowOffset = 0;

  /// 单次加载最多顺带翻的页数上限
  ///
  /// 只在「整页都没有视频」时才会连续翻页；没有上限时，历史里若全是文章 / 动态，
  /// 一次 `loadMore` 会变成读到表尾为止的循环。
  static const int _maxPagesPerFetch = 10;

  /// 追加下一页
  Future<void> loadMore() async {
    // 已有请求在飞时不重复触发：用户连点「加载更多」会打出并发查询，
    // 后到的响应携带重复的 offset，列表出现重复条目。
    if (_isClosing || state.isLoading) return;
    if (!state.hasMore) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    await _stopWatching();
    await _fetch(offset: _rowOffset, replace: false);
  }

  /// 重新拉取第一页
  ///
  /// [loadMore] 是追加语义（offset 基于已消费行数），只适合滚动加载。刷新要回到
  /// 起点，因此单列一条路径，而不是给 [loadMore] 加布尔开关——两种 offset 基准
  /// 混在一个方法里最容易在边界上算错。
  Future<void> refresh() async {
    if (_isClosing || state.isLoading) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    await _stopWatching();
    await _fetch(offset: 0, replace: true);
  }

  /// 取一页并写回状态
  ///
  /// [replace] 为 true 时用本页结果替换列表（刷新），否则追加（翻页）。
  Future<void> _fetch({required int offset, required bool replace}) async {
    final items = replace ? <MediaHistoryItem>[] : [...state.items];
    final progressByMedia = replace
        ? <MediaHistoryProgressKey, MediaHistoryProgress>{}
        : {...state.progressByMedia};
    var cursor = offset;
    var hasMore = true;

    try {
      for (var page = 0; page < _maxPagesPerFetch; page++) {
        final rows = await _mediaHistoryDao.getHistoryWithMedia(
          limit: _pageSize,
          offset: cursor,
        );
        cursor += rows.length;
        // 用 DAO 返回的行数判断是否到底，而不是转换后的条数：非视频条目会被过滤，
        // 用过滤后的长度判断会误判为「还有更多」而多翻一页空页。
        hasMore = rows.length == _pageSize;

        final pageData = _historyData(rows);
        items.addAll(pageData.items);
        progressByMedia.addAll(pageData.progressByMedia);

        // 整页都没有视频但还有下一页时继续翻：本页过滤后为空会让界面显示「还没有
        // 观看记录」，而翻页按钮在列表为空时是禁用的，视频就永远到不了。
        if (pageData.items.isNotEmpty || !hasMore) break;
      }

      _rowOffset = cursor;
      if (_isClosing || isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          items: items,
          progressByMedia: progressByMedia,
          hasMore: hasMore,
        ),
      );
      await _watchVisibleHistory();
    } catch (e) {
      // cubit 已关闭时 emit 会抛 StateError，这个 catch 会把它吞掉、再抛一次，
      // 于是「页面已离开」这种正常收尾变成未捕获异常。
      if (_isClosing || isClosed) return;
      emit(state.copyWith(isLoading: false, error: '$e'));
      await _watchVisibleHistory();
    }
  }

  /// Starts a bounded stream for all consumed rows plus one pagination sentinel.
  Future<void> _watchVisibleHistory() async {
    if (_isClosing || isClosed) return;
    final generation = ++_watchGeneration;
    final limit = _rowOffset == 0 ? 1 : _rowOffset + 1;
    _historySubscription = _mediaHistoryDao
        .watchHistoryWithMedia(limit: limit)
        .listen(
          (rows) {
            if (generation != _watchGeneration || _isClosing || isClosed) {
              return;
            }

            // An initially empty history has no consumed rows to watch. A
            // later insert therefore refreshes the first page once, after
            // which the normal bounded window takes over.
            if (_rowOffset == 0) {
              if (rows.isNotEmpty && !state.isLoading) unawaited(refresh());
              return;
            }

            final visibleRows = rows.take(_rowOffset);
            final data = _historyData(visibleRows);
            emit(
              state.copyWith(
                items: data.items,
                progressByMedia: data.progressByMedia,
                hasMore: rows.length > _rowOffset,
              ),
            );
          },
          onError: (Object error, StackTrace stackTrace) {
            if (generation != _watchGeneration || _isClosing || isClosed) {
              return;
            }
            emit(state.copyWith(error: '$error'));
          },
        );
  }

  /// Stops the current bounded history stream before changing its offset.
  Future<void> _stopWatching() async {
    ++_watchGeneration;
    final subscription = _historySubscription;
    _historySubscription = null;
    await subscription?.cancel();
  }

  ({
    List<MediaHistoryItem> items,
    Map<MediaHistoryProgressKey, MediaHistoryProgress> progressByMedia,
  })
  _historyData(Iterable<MediaHistoryWithMedia> rows) {
    final items = <MediaHistoryItem>[];
    final progressByMedia = <MediaHistoryProgressKey, MediaHistoryProgress>{};
    for (final row in rows) {
      // 非视频条目（文章 / 动态）当前无展示位，跳过但照常计入 offset。
      if (row.media.type != Media.typeVideo) continue;
      items.add((
        video: _toVideoModel(row.media),
        sourceId: row.media.sourceId,
        viewedAt: row.history.accessedAt,
      ));
      progressByMedia[(
        sourceId: row.media.sourceId,
        originalId: row.media.originalId,
      )] = MediaHistoryProgress(
        progressSeconds: row.history.progressSeconds?.toInt(),
        completed: row.history.completed,
      );
    }
    return (items: items, progressByMedia: progressByMedia);
  }

  @override
  Future<void> close() async {
    _isClosing = true;
    await _stopWatching();
    await super.close();
  }

  /// 把媒体行转成视频模型
  ///
  /// `viewCount` 与 `duration` 在 `media` 表里没有对应列，因此留空而不是填 0：
  /// 填 0 会让卡片副标题渲染出「0 播放」和「00:00」角标。播放进度保留在
  /// [MediaHistoryProgress] 中，不混入远端视频模型。
  static VideoModel _toVideoModel(MediaEntity media) => VideoModel(
    id: media.originalId,
    title: media.title,
    url: media.url,
    thumbnailUrl: media.thumbnailUrl,
    uploadDate: media.uploadDate,
    creatorProfileName: media.creatorProfileName,
    creatorProfileId: media.creatorProfileId,
  );
}

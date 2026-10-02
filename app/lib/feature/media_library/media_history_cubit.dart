import 'package:bloc/bloc.dart';
import 'package:data/data.dart';

import '../../database/app_database.dart';
import '../../database/dao/media_history_dao.dart';
import '../../database/table/media.dart';

part 'media_history_state.dart';

/// 观看历史加载器
///
/// 历史表按 `accessedAt` 倒序，新观看会插到最前，因此**不去重**：同一视频看两次
/// 会出现两条，这正是「历史」而非「收藏」的语义。
class MediaHistoryCubit({
  required final MediaHistoryDao mediaHistoryDao,
  final int pageSize = 20,
}) extends Cubit<MediaHistoryState> {
  this : _mediaHistoryDao = mediaHistoryDao,
      _pageSize = pageSize,
      super(const MediaHistoryState()) {
    loadMore();
  }

  final MediaHistoryDao _mediaHistoryDao;

  /// 单页条数
  final int _pageSize;

  /// 历史条目 id 到数据源标识的映射，供 [sourceOf] 查询
  final Map<String, String> _sourceById = {};

  /// 取某个历史条目的数据源标识
  ///
  /// 历史跨源存放，跳转详情页时必须带上：缺省会落到当前默认源，用错源的接口
  /// 取详情会失败。找不到时返回 null，由调用方回落到默认源。
  String? sourceOf(String originalId) => _sourceById[originalId];

  /// 追加下一页
  Future<void> loadMore() async {
    // 已有请求在飞时不重复触发：用户连点「加载更多」会打出并发查询，
    // 后到的响应携带重复的 offset，列表出现重复条目。
    if (state.isLoading) return;
    if (!state.hasMore) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    await _fetch(offset: state.items.length, replace: false);
  }

  /// 重新拉取第一页
  ///
  /// [loadMore] 是追加语义（offset 基于已有条数），只适合滚动加载。刷新要回到
  /// 起点，因此单列一条路径，而不是给 [loadMore] 加布尔开关——两种 offset 基准
  /// 混在一个方法里最容易在边界上算错。
  Future<void> refresh() async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    await _fetch(offset: 0, replace: true);
  }

  /// 取一页并写回状态
  ///
  /// [replace] 为 true 时用本页结果替换列表（刷新），否则追加（翻页）。
  Future<void> _fetch({required int offset, required bool replace}) async {
    try {
      final rows = await _mediaHistoryDao.getHistoryWithMedia(
        limit: _pageSize,
        offset: offset,
      );

      final videos = <VideoModel>[];
      final sources = <String, String>{};
      for (final row in rows) {
        // 非视频条目（文章 / 动态）当前无展示位，跳过但不影响分页判断。
        if (row.media.type != Media.typeVideo) continue;
        videos.add(_toVideoModel(row.media));
        sources[row.media.originalId] = row.media.sourceId;
      }

      // 刷新时清空旧映射：残留的 id 可能已不在第一页，留着会让已删历史的条目
      // 仍解析出一个过时数据源。
      if (replace) _sourceById.clear();
      _sourceById.addAll(sources);

      emit(
        state.copyWith(
          isLoading: false,
          items: replace ? videos : [...state.items, ...videos],
          // 用 DAO 返回的行数判断是否到底，而不是转换后的 videos.length：
          // 非视频条目会被过滤，用过滤后的长度判断会误判为「还有更多」而多翻
          // 一页空页。
          hasMore: rows.length == _pageSize,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: '$e'));
    }
  }

  /// 把媒体行转成视频模型
  ///
  /// `viewCount` 与 `duration` 在 `media` 表里没有对应列，仓内也没有落库位置
  ///（`media_history` 只记 `accessedAt`），因此留空而不是填 0：填 0 会让卡片
  /// 副标题渲染出「0 播放」和「00:00」角标。
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

part of 'media_history_cubit.dart';

/// A saved playback position for a history item.
@immutable
final class const MediaHistoryProgress({
  final int? progressSeconds,
  required final bool completed,
}) extends Equatable {
  @override
  List<Object?> get props => [progressSeconds, completed];
}

@immutable
class const MediaHistoryState({
  /// 已加载的历史条目（按访问时间倒序）
  final List<MediaHistoryItem> items = const [],

  /// 每个视频的播放进度，键包含数据源和原始媒体 id。
  final Map<MediaHistoryProgressKey, MediaHistoryProgress> progressByMedia =
      const {},

  /// 是否有请求在飞
  final bool isLoading = false,

  /// 是否还有下一页
  final bool hasMore = true,

  /// 最近一次加载的错误信息，null 表示无错
  final String? error,
}) extends Equatable {
  /// Returns the saved progress for an item, if one is loaded.
  MediaHistoryProgress? progressFor(MediaHistoryItem item) =>
      progressByMedia[(sourceId: item.sourceId, originalId: item.video.id)];

  MediaHistoryState copyWith({
    List<MediaHistoryItem>? items,
    Map<MediaHistoryProgressKey, MediaHistoryProgress>? progressByMedia,
    bool? isLoading,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return MediaHistoryState(
      items: List.unmodifiable(items ?? this.items),
      progressByMedia: Map.unmodifiable(
        progressByMedia ?? this.progressByMedia,
      ),
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    items,
    progressByMedia,
    isLoading,
    hasMore,
    error,
  ];
}

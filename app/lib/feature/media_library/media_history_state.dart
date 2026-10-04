part of 'media_history_cubit.dart';

// 💡 类头括号里写了 final，类体内不再需要写成员变量声明

class const MediaHistoryState({
  /// 已加载的历史条目（按访问时间倒序）
  final List<MediaHistoryItem> items = const [],

  /// 是否有请求在飞
  final bool isLoading = false,

  /// 是否还有下一页
  final bool hasMore = true,

  /// 最近一次加载的错误信息，null 表示无错
  final String? error,
}) {

  MediaHistoryState copyWith({
    List<MediaHistoryItem>? items,
    bool? isLoading,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return MediaHistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

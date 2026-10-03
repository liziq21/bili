part of 'media_history_cubit.dart';

// 💡 类头括号里写了 final，类体内不再需要写成员变量声明

class const MediaHistoryState({
  final List<MediaHistoryItem> items = const [],
  final bool isLoading = false,
  final bool hasMore = true,
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

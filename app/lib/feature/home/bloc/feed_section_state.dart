import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// 单个 Feed 区块的加载状态
enum FeedStatus() { initial, loading, loadingMore, success, failure }

/// 主页单个 Feed 区块（视频流或直播流）的状态
@immutable
final class const FeedSectionState<T>({
  required final String id,
  required final String title,
  final FeedStatus status = FeedStatus.initial,
  final List<T> items = const [],
  final int pageKey = 0,
  final bool hasMore = false,
  final Object? error,
}) extends Equatable {
  /// 首屏加载中（尚无任何数据可展示）
  bool get isInitialLoading => status == FeedStatus.loading && items.isEmpty;

  /// 正在追加下一页
  bool get isLoadingMore => status == FeedStatus.loadingMore;

  /// 加载失败且无任何可展示数据
  bool get isFailure => status == FeedStatus.failure && items.isEmpty;

  /// 加载成功但结果为空
  bool get isEmpty => status == FeedStatus.success && items.isEmpty;

  FeedSectionState<T> copyWith({
    FeedStatus? status,
    List<T>? items,
    int? pageKey,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) => FeedSectionState<T>(
    id: id,
    title: title,
    status: status ?? this.status,
    items: items ?? this.items,
    pageKey: pageKey ?? this.pageKey,
    hasMore: hasMore ?? this.hasMore,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [
    id,
    title,
    status,
    items,
    pageKey,
    hasMore,
    error,
  ];
}

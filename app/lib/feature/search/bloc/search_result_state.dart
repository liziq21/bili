part of 'search_result_bloc.dart';

const Object _unset = Object();

final class const SearchResultState<T>({
  required final String query,
  final List<FilterGroup> filters = const [],
  final List<SortOption> sortOption = const [],
  final SortOption? currentSort,
  final bool pendingRefresh = false,
  required final PagingState<int, T> pagingState,
}) extends Equatable {
  /// 待刷新时固定回第一页：排序/筛选变化后即使首屏请求失败，重试也必须重跑
  /// 第 1 页，而不是沿着旧结果翻到下一页。
  SearchQuery get searchQuery => .new(
    query: query,
    sortOption: currentSort,
    filters: filters,
    pageKey: pendingRefresh ? 1 : pagingState.nextIntPageKey,
  );

  SearchResultState<T> toLoading() {
    return copyWith(pagingState: pagingState.copyWith(isLoading: true));
  }

  SearchResultState<T> updatePagingStete(
    PagingState<int, T> Function(PagingState<int, T>) update,
  ) {
    return copyWith(pagingState: update(pagingState));
  }

  SearchResultState<T> toResult(PagingState<int, T> newPagingState) {
    return copyWith(pagingState: newPagingState);
  }

  @override
  List<Object?> get props => [
    query,
    filters,
    sortOption,
    currentSort,
    pendingRefresh,
    pagingState,
  ];

  SearchResultState<T> copyWith({
    String? query,
    List<FilterGroup>? filters,
    List<SortOption>? sortOption,
    Object? currentSort = _unset,
    bool? pendingRefresh,
    PagingState<int, T>? pagingState,
  }) => SearchResultState<T>(
    query: query ?? this.query,
    filters: filters ?? this.filters,
    sortOption: sortOption ?? this.sortOption,
    currentSort: identical(currentSort, _unset)
        ? this.currentSort
        : currentSort as SortOption?,
    pendingRefresh: pendingRefresh ?? this.pendingRefresh,
    pagingState: pagingState ?? this.pagingState,
  );
}

part of 'search_result_bloc.dart';

const Object _unset = Object();

final class const SearchResultState<T>({
  required final String query,
  final List<FilterGroup> filters = const [],
  final List<SortOption> sortOption = const [],
  final SortOption? currentSort,
  required final PagingState<int, T> pagingState,
}) extends Equatable {
  SearchQuery get searchQuery => .new(
    query: query,
    sortOption: currentSort,
    filters: filters,
    pageKey: (pagingState.keys?.last ?? 0) + 1,
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
    pagingState,
  ];

  SearchResultState<T> copyWith({
    String? query,
    List<FilterGroup>? filters,
    List<SortOption>? sortOption,
    Object? currentSort = _unset,
    PagingState<int, T>? pagingState,
  }) => SearchResultState<T>(
    query: query ?? this.query,
    filters: filters ?? this.filters,
    sortOption: sortOption ?? this.sortOption,
    currentSort: identical(currentSort, _unset)
        ? this.currentSort
        : currentSort as SortOption?,
    pagingState: pagingState ?? this.pagingState,
  );
}

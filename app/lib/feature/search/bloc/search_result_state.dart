part of 'search_result_bloc.dart';

final class SearchResultState<T> extends Equatable {
  const SearchResultState({
    this.query = 'vtuber',
    this.filters = const [],
    this.sortOption = const [],
    this.currentSort,
    required this.pagingState,
  });

  final String query;
  final List<FilterGroup> filters;
  final List<SortOption> sortOption;
  final SortOption? currentSort;
  final PagingState<int, T> pagingState;

  SearchQuery get searchQuery => SearchQuery(
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
    SortOption? currentSort,
    PagingState<int, T>? pagingState,
  }) => SearchResultState<T>(
    query: query ?? this.query,
    filters: filters ?? this.filters,
    sortOption: sortOption ?? this.sortOption,
    currentSort: currentSort ?? this.currentSort,
    pagingState: pagingState ?? this.pagingState,
  );
}

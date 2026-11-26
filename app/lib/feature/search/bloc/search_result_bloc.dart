import 'package:bloc/bloc.dart';
import 'package:data/data.dart';
// ignore: depend_on_referenced_packages
import 'package:equatable/equatable.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:model/model.dart';

import '../../../data/repository/search_contents_repository.dart';

part 'search_result_event.dart';
part 'search_result_state.dart';

class SearchResultBloc<T>({
  required final SearchContentsRepository<T> searchContentsRepository,
  required final String query,
}) extends Bloc<SearchResultEvent, SearchResultState<T>> {
  this
    : super(
        SearchResultState(
          query: query,
          filters: searchContentsRepository.filters,
          sortOption: searchContentsRepository.sortOptions,
          currentSort: searchContentsRepository.sortOptions.isEmpty
              ? null
              : searchContentsRepository.sortOptions.first,
          pagingState: .new(),
        ),
      ) {
    on<FetchNextPage>(_fetchNextPage);
    on<ApplySearchOptions>(_applySearchOptions);
  }

  List<FilterGroup> get defaultFilters => searchContentsRepository.filters;

  List<SortOption> get defaultSortOptions =>
      searchContentsRepository.sortOptions;

  /// 每次筛选变化递增。旧请求返回时若代次已变，结果直接丢弃，避免慢请求
  /// 覆盖用户刚切换的筛选结果。
  int _generation = 0;

  Future<void> _applySearchOptions(
    ApplySearchOptions event,
    Emitter<SearchResultState> emit,
  ) async {
    _generation++;
    emit(
      state.copyWith(
        filters: List.unmodifiable(event.filters),
        currentSort: event.sortOption,
        pagingState: .new(),
      ),
    );
    await _fetchNextPage(const FetchNextPage(), emit);
  }

  Future<void> _fetchNextPage(
    FetchNextPage event,
    Emitter<SearchResultState> emit,
  ) async {
    if (state.pagingState.isLoading) return;

    emit(
      state.updatePagingStete(
        (pagingState) => pagingState.copyWith(isLoading: true),
      ),
    );

    final generation = _generation;
    final searchQuery = state.searchQuery;
    final result = await searchContentsRepository.search(searchQuery);
    if (generation != _generation) return;

    emit(
      state.updatePagingStete(
        (pagingState) => switch (result) {
          Success(:final success) => pagingState.copyWith(
            pages: [...pagingState.pages, success.data],
            keys: [...pagingState.keys, searchQuery.pageKey],
            hasNextPage: searchQuery.pageKey < success.totalPages,
            isLoading: false,
          ),
          Error(:final error) => pagingState.copyWith(
            error: error,
            isLoading: false,
          ),
        },
      ),
    );
  }
}

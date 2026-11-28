import 'package:bloc/bloc.dart';
import 'package:data/data.dart';
// ignore: depend_on_referenced_packages
import 'package:equatable/equatable.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:logging/logging.dart';
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
    // 事件必须串行处理。bloc 默认的 transformer 是并发派发，排序/筛选事件
    // 会和在途的分页请求同时发出，同一风控窗口里叠出多个请求，一改排序就
    // 直接撞上平台的限流。串行后新请求总要等上一个结束，不再叠加。
    on<SearchResultEvent>(
      _handleEvent,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  List<FilterGroup> get defaultFilters => searchContentsRepository.filters;

  final _log = Logger('SearchResultBloc');

  List<SortOption> get defaultSortOptions =>
      searchContentsRepository.sortOptions;

  Future<void> _handleEvent(
    SearchResultEvent event,
    Emitter<SearchResultState<T>> emit,
  ) async {
    switch (event) {
      case FetchNextPage():
        await _fetchNextPage(emit);
      case ApplySearchOptions(:final filters, :final sortOption):
        await _applySearchOptions(filters, sortOption, emit);
    }
  }

  Future<void> _applySearchOptions(
    List<FilterGroup> filters,
    SortOption? sortOption,
    Emitter<SearchResultState<T>> emit,
  ) async {
    final nextFilters = List<FilterGroup>.unmodifiable(filters);
    if (!state.pendingRefresh &&
        _sameFilters(state.filters, nextFilters) &&
        state.currentSort?.value == sortOption?.value) {
      return;
    }

    // 保留已加载的结果：排序/筛选变化只是同一查询的视图变更，刷新失败时
    // 不应把整页内容换成错误态。pendingRefresh 让重试固定在新的第一页。
    emit(
      state.copyWith(
        filters: nextFilters,
        currentSort: sortOption,
        pendingRefresh: true,
        pagingState: state.pagingState.copyWith(isLoading: true, error: null),
      ),
    );
    await _runSearch(emit);
  }

  Future<void> _fetchNextPage(Emitter<SearchResultState<T>> emit) async {
    if (state.pagingState.isLoading) return;
    await _runSearch(emit);
  }

  Future<void> _runSearch(Emitter<SearchResultState<T>> emit) async {
    final pendingRefresh = state.pendingRefresh;
    final searchQuery = state.searchQuery;

    emit(
      state.updatePagingStete(
        (pagingState) => pagingState.copyWith(isLoading: true, error: null),
      ),
    );

    final result = await searchContentsRepository.search(searchQuery);

    switch (result) {
      case Success(:final success):
        emit(
          state.copyWith(
            pendingRefresh: false,
            pagingState: state.pagingState.copyWith(
              pages: pendingRefresh
                  ? [success.data]
                  : [...state.pagingState.pages, success.data],
              keys: pendingRefresh
                  ? [searchQuery.pageKey]
                  : [...state.pagingState.keys, searchQuery.pageKey],
              hasNextPage: searchQuery.pageKey < success.totalPages,
              isLoading: false,
              error: null,
            ),
          ),
        );
      case Error(:final error):
        _log.warning('Search failed (page: ${searchQuery.pageKey})', error);
        emit(
          state.copyWith(
            // pendingRefresh 保持不变：刷新失败后重试仍要重跑第 1 页。
            pagingState: state.pagingState.copyWith(
              error: error,
              isLoading: false,
            ),
          ),
        );
    }
  }
}

bool _sameFilters(List<FilterGroup> left, List<FilterGroup> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i].toQueryParams().toString() !=
        right[i].toQueryParams().toString()) {
      return false;
    }
  }
  return true;
}

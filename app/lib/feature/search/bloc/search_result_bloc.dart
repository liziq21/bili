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
    // 请求全部由一个驱动循环串行发出：排序/筛选事件不直接查数据，只登记
    // 最新的选择，由循环在空闲时取最新值发一次请求。这样既不会和在途请求
    // 叠在同一个风控窗口里，也会把期间多次改动合并成一次请求。
    on<ApplySearchOptions>(_onApplySearchOptions);
    on<FetchNextPage>(_onFetchNextPage);
  }

  List<FilterGroup> get defaultFilters => searchContentsRepository.filters;

  final _log = Logger('SearchResultBloc');

  List<SortOption> get defaultSortOptions =>
      searchContentsRepository.sortOptions;

  /// 最新的期望选择。多次改动在同一个请求期间到达时，只保留最后一次。
  List<FilterGroup>? _desiredFilters;
  SortOption? _desiredSort;
  bool _refreshRequested = false;
  bool _nextPageRequested = false;

  /// 同一时刻只有一个驱动循环，所有请求都由它串行发出。
  bool _pumping = false;

  Future<void> _onApplySearchOptions(
    ApplySearchOptions event,
    Emitter<SearchResultState<T>> emit,
  ) async {
    final filters = List<FilterGroup>.unmodifiable(event.filters);
    if (!state.pendingRefresh &&
        _sameFilters(state.filters, filters) &&
        state.currentSort?.value == event.sortOption?.value) {
      return;
    }

    _desiredFilters = filters;
    _desiredSort = event.sortOption;
    _refreshRequested = true;
    // 立刻反映选择：刷新请求可能要等当前请求结束，状态不应停留在旧值。
    // 保留已加载的结果，刷新失败时不要把整页内容换成错误态。
    emit(
      state.copyWith(
        filters: filters,
        currentSort: event.sortOption,
        pendingRefresh: true,
        pagingState: state.pagingState.copyWith(isLoading: true, error: null),
      ),
    );
    await _pump(emit);
  }

  Future<void> _onFetchNextPage(
    FetchNextPage event,
    Emitter<SearchResultState<T>> emit,
  ) async {
    // 正在请求时到达的重复翻页请求直接丢弃：排队执行会让结果多翻一页。
    if (state.pagingState.isLoading) return;
    _nextPageRequested = true;
    await _pump(emit);
  }

  Future<void> _pump(Emitter<SearchResultState<T>> emit) async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (true) {
        if (_refreshRequested) {
          _refreshRequested = false;
          emit(
            state.copyWith(
              filters: _desiredFilters ?? state.filters,
              currentSort: _desiredSort,
              pendingRefresh: true,
              pagingState: state.pagingState.copyWith(
                isLoading: true,
                error: null,
              ),
            ),
          );
          await _runSearch(emit);
          continue;
        }
        if (_nextPageRequested) {
          _nextPageRequested = false;
          await _runSearch(emit);
          continue;
        }
        break;
      }
    } finally {
      _pumping = false;
    }
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

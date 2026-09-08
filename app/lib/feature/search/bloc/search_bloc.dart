import 'dart:async';

import 'package:model/model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../data/model/recent_search_query.dart';
import '../../../data/repository/recent_search_query/recent_search_query_repository.dart';
import '../../../data/repository/search_suggest_repository.dart';
import '../../../domain/get_recent_search_queries_use_case.dart';
part 'search_state.dart';
part 'search_event.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({
    required GetRecentSearchQueriesUseCase getRentSearchQueriesUseCase,
    required RecentSearchQueryRepository recentSearchQueryRepository,
    required SearchSuggestRepository searchSuggestRepository,
    String initQuery = '',
  })  : _getRentSearchQueriesUseCase = getRentSearchQueriesUseCase,
        _recentSearchQueryRepository = recentSearchQueryRepository,
        _searchSuggestRepository = searchSuggestRepository,
        super(SearchState(currentQuery: initQuery)) {
    on<MonitorRecentSearches>(_onMonitorRecentSearches);
    on<SearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: (events, mapper) =>
          events.debounce(const Duration(milliseconds: 300)).switchMap(mapper),
    );
    on<ClearRecentSearchesPressed>(_onClearRecentSearchesPressed);
    on<RecentSearchUpdated>(_onRecentSearchUpdated);
  }

  final GetRecentSearchQueriesUseCase _getRentSearchQueriesUseCase;
  final RecentSearchQueryRepository _recentSearchQueryRepository;
  final SearchSuggestRepository _searchSuggestRepository;
  final _log = Logger('AppSearchBarBloc');

  // 处理最近搜索流：emit.forEach 自动接管生命周期，销毁时自动注销
  Future<void> _onMonitorRecentSearches(
    MonitorRecentSearches event,
    Emitter<SearchState> emit,
  ) async {
    await emit.forEach<List<RecentSearchQuery>>(
      _getRentSearchQueriesUseCase.invoke(),
      onData: (queries) => state.copyWith(recentSearchQueries: queries),
      onError: (error, stackTrace) {
        _log.warning('加载最近搜索失败', error);
        return state.copyWith(recentSearchQueries: []);
      },
    );
  }

  // 处理输入文字联想
  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query;
    if (query.isEmpty) {
      emit(state.copyWith(suggests: [], currentQuery: ''));
      return;
    }

    _log.fine('Load suggests for: $query');
    final result = await _searchSuggestRepository.getSuggests(query);

    switch (result) {
      case Ok(:final value):
        _log.fine('Suggests (${value.length}) loaded');
        emit(state.copyWith(suggests: value, currentQuery: query));
      case Error():
        _log.warning('Failed to load suggests');
        emit(state.copyWith(suggests: [], currentQuery: query));
    }
  }

  // 清除历史记录
  Future<void> _onClearRecentSearchesPressed(
    ClearRecentSearchesPressed event,
    Emitter<SearchState> emit,
  ) async {
    await _recentSearchQueryRepository.clearRecentSearchQueries();
  }

  // 更新/增加历史记录
  Future<void> _onRecentSearchUpdated(
    RecentSearchUpdated event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.isEmpty) return;
    await _recentSearchQueryRepository.insertOrReplaceRecentSearch(event.query);
    _log.info('add recent search: ${event.query}');
  }
}

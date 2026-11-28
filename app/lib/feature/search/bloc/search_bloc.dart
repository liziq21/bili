import 'dart:async';

import 'package:model/model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../datastore/preferences_data_source.dart';
import '../../../data/model/recent_search_query.dart';
import '../../../data/repository/recent_search_query/recent_search_query_repository.dart'
    show RecentSearchQueryRepository;
import '../../../data/repository/search_suggest_repository.dart';
import '../../../domain/get_recent_search_queries_use_case.dart';
part 'search_state.dart';
part 'search_event.dart';

class SearchBloc({
  required final GetRecentSearchQueriesUseCase _getRentSearchQueriesUseCase,
  required final RecentSearchQueryRepository _recentSearchQueryRepository,
  required final SearchSuggestRepository _searchSuggestRepository,
  required final PreferencesDataSource _preferences,
  String initQuery = '',
}) extends Bloc<SearchEvent, SearchState> {
  this : super(SearchState(currentQuery: initQuery)) {
    on<MonitorRecentSearches>(_onMonitorRecentSearches);
    on<SearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: (events, mapper) =>
          events.debounce(const Duration(milliseconds: 300)).switchMap(mapper),
    );
    on<ClearRecentSearchesPressed>(_onClearRecentSearchesPressed);
    on<DeleteRecentSearchPressed>(_onDeleteRecentSearchPressed);
    on<RecentSearchUpdated>(_onRecentSearchUpdated);
    on<CleanupOldSearchQueries>(_onCleanupOldSearchQueries);

    // 触发一次性清理（fire-and-forget，不阻塞启动）
    add(CleanupOldSearchQueries());
  }

  final _log = Logger('AppSearchBarBloc');

  /// 在途的建议请求。提交搜索时先等它落地，避免建议请求与首个结果请求
  /// 落进同一个风控窗口——switchMap 只取消订阅，停不掉已经发出的 HTTP。
  Future<void>? _pendingSuggests;

  /// 提交前把还没发出去的建议请求标记为作废。
  ///
  /// 建议请求要经过 300ms debounce 才发出；用户输入后立刻回车时请求还在
  /// 定时器里排队，提交后再发出去就会和结果请求撞进同一窗口。这里只打标记，
  /// 不额外发事件：新事件会再排一个 300ms 定时器，而定时器到期时对应的
  /// [SearchQueryChanged] 会自己跳过网络。
  String? _skippedSuggestsQuery;

  /// 当前在途的建议请求，没有则为 null。调用方可以 `await` 它。
  Future<void>? get pendingSuggests => _pendingSuggests;

  /// 提交搜索时调用：作废尚未发出的建议请求。
  void skipPendingSuggests(String query) {
    _skippedSuggestsQuery = query;
  }

  // 处理最近搜索流：emit.forEach 自动接管生命周期，销毁时自动注销
  Future<void> _onMonitorRecentSearches(
    MonitorRecentSearches event,
    Emitter<SearchState> emit,
  ) async {
    await emit.forEach<List<RecentSearchQuery>>(
      _getRentSearchQueriesUseCase.invoke(),
      onData: (queries) => state.copyWith(recentSearchQueries: queries),
      onError: (error, stackTrace) {
        _log.warning('Failed to load recent searches', error);
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

    // 这条查询在 debounce 期间已经被提交去搜索结果页：不再发建议请求，
    // 只把状态对齐到输入框，让等待中的浮层立刻拿到空建议。
    final skipped = query == _skippedSuggestsQuery;
    _skippedSuggestsQuery = null;
    if (skipped) {
      _log.fine('Skip suggests for a submitted query: $query');
      emit(state.copyWith(suggests: [], currentQuery: query));
      return;
    }

    _log.fine('Load suggests for: $query');
    final request = _searchSuggestRepository.getSuggests(query);
    _pendingSuggests = request;
    Result<List<String>, Exception> result;
    try {
      result = await request;
    } finally {
      if (identical(_pendingSuggests, request)) _pendingSuggests = null;
    }

    switch (result) {
      case Success(:final success):
        _log.fine('Suggests () loaded');
        emit(state.copyWith(suggests: success, currentQuery: query));
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

  // 删除单条历史记录
  Future<void> _onDeleteRecentSearchPressed(
    DeleteRecentSearchPressed event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.isEmpty) return;
    await _recentSearchQueryRepository.deleteRecentSearchQuery(event.query);
    _log.info('deleted recent search: ${event.query}');
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

  // 清理过期搜索历史
  Future<void> _onCleanupOldSearchQueries(
    CleanupOldSearchQueries event,
    Emitter<SearchState> emit,
  ) async {
    final retentionResult = await _preferences.get(
      PreferencesKey.searchHistoryRetentionDays,
    );
    final retentionDays = retentionResult is Success<int, Exception>
        ? retentionResult.success
        : 30;

    if (retentionDays <= 0) {
      _log.fine(
        'Search history retention is forever (days=$retentionDays), skipping cleanup',
      );
      return;
    }

    await _recentSearchQueryRepository.deleteOldSearchQueries(retentionDays);
    _log.info('Cleaned up search queries older than $retentionDays days');
  }
}

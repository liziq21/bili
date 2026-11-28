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

  /// 尚未落地的建议请求数量。提交搜索时要等它们全部结束，避免建议请求与
  /// 首个结果请求落进同一个风控窗口——switchMap 只取消订阅，停不掉已经发出
  /// 的 HTTP，被切走的旧请求也仍在跑，所以必须按数量跟踪而不是只留最新一个。
  int _inFlightSuggests = 0;
  Completer<void>? _suggestsSettled;

  /// 建议请求的世代。`skipPendingSuggests` 自增它，debounce 里排队的旧事件
  /// 带着旧世代，到期时直接跳过网络。
  int _suggestsEpoch = 0;

  /// 正在进行的建议请求都落地后完成；没有在途请求时为 null。
  Future<void>? get pendingSuggests => _inFlightSuggests == 0
      ? null
      : (_suggestsSettled ??= Completer<void>()).future;

  /// 请求某个查询的建议。
  ///
  /// 事件自带当前世代，提交搜索时 [skipPendingSuggests] 一自增，所有还排在
  /// debounce 里的旧事件都会失效——不依赖提交的词与被防抖的输入是否相同。
  void requestSuggests(String query) =>
      add(SearchQueryChanged(query, _suggestsEpoch));

  /// 提交搜索时调用：作废尚未发出的建议请求。在途请求不受影响，调用方应
  /// 先 await 一次 [pendingSuggests] 再发结果请求。
  void skipPendingSuggests() => _suggestsEpoch++;

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

    // 这条查询在排队期间已经被提交去搜索结果页：不再发建议请求，只把状态
    // 对齐到输入框，让等待中的浮层立刻拿到空建议。
    if (event.suggestsEpoch != _suggestsEpoch) {
      _log.fine('Skip suggests for a submitted query: $query');
      emit(state.copyWith(suggests: [], currentQuery: query));
      return;
    }

    _log.fine('Load suggests for: $query');
    _inFlightSuggests++;
    Result<List<String>, Exception> result;
    try {
      result = await _searchSuggestRepository.getSuggests(query);
    } finally {
      _inFlightSuggests--;
      if (_inFlightSuggests == 0) {
        _suggestsSettled?.complete();
        _suggestsSettled = null;
      }
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

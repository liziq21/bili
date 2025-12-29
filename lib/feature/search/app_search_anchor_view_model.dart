import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../bili/constonts/constonts.dart';
import '../../data/repository/recent_search_query/recent_search_query_repository.dart';
import '../../data/repository/search_suggest/search_suggest_repository.dart';
import '../../data/model/recent_search_query.dart';
import '../../domain/get_recent_search_queries_use_case.dart';
import '../../utils/result.dart';

class AppSearchAnchorViewModel extends ChangeNotifier {
  AppSearchAnchorViewModel({
    required GetRecentSearchQueriesUseCase getRecentSearchQueriesUseCase,
    required RecentSearchQueryRepository recentSearchQueryRepository,
    required SearchSuggestRepository searchSuggestRepository,
  }) : _recentSearchQueryRepository = recentSearchQueryRepository,
       _searchSuggestRepository = searchSuggestRepository {
    recentSearchQueries = getRecentSearchQueriesUseCase.invoke();
  }
  
  final _log = Logger('AppSearchBarViewModel');
  late final RecentSearchQueryRepository _recentSearchQueryRepository;
  late final SearchSuggestRepository _searchSuggestRepository;

  String? _currentQuery;
  Iterable<String> _suggests = [];
  
  late final Stream<List<RecentSearchQuery>> recentSearchQueries;

  //clearRecentSearches
  
  Future<Iterable<String>> getSuggests(String query) async {
    if (_currentQuery == query) {
      return _suggests;
    } else {
      await _debounceLoadSuggests(_currentQuery!);
      if (_currentQuery == query) {
        return _suggests;
      }
    }
    return [];
  }
  
  late final _debounceLoadSuggests = _debounce<void, String>(_loadSuggests);
  
  Future<void> _loadSuggests(String query) async {
    _log.fine('Load suggests');
    final result = await _searchSuggestRepository.getSuggests(query);
    switch (result) {
      case Ok(:final value):
        _log.fine('Suggests (${value.length}) loaded');
        _suggests = value;
        _currentQuery = query;
      case Error():
        _log.warning('Failed to load suggests', result.error);
        _suggests = [];
    }
  }
}

const Duration debounceDuration = Duration(milliseconds: 300);

typedef _Debounceable<S, T> = Future<S?> Function(T parameter);

_Debounceable<S, T> _debounce<S, T>(_Debounceable<S?, T> function) {
  _DebounceTimer? debounceTimer;

  return (T parameter) async {
    if (debounceTimer != null && !debounceTimer!.isCompleted) {
      debounceTimer!.cancel();
    }
    debounceTimer = _DebounceTimer();
    try {
      await debounceTimer!.future;
    } on _CancelException {
      return null;
    }
    return function(parameter);
  };
}

class _DebounceTimer {
  _DebounceTimer() {
    _timer = Timer(debounceDuration, _onComplete);
  }

  late final Timer _timer;
  final Completer<void> _completer = Completer<void>();

  void _onComplete() {
    _completer.complete();
  }

  Future<void> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  void cancel() {
    _timer.cancel();
    _completer.completeError(const _CancelException());
  }
}

class _CancelException implements Exception {
  const _CancelException();
}

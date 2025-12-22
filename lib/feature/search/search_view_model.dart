import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'package:logger/logger.dart';
import 'package:logging/logging.dart';

import '../../bili/constonts/constonts.dart';
import '../../data/repository/recent_search_query/recent_search_query_repository.dart';
import '../../data/repository/search_contents/search_contents_repository.dart';
import '../../data/repository/search_suggest/search_suggest_repository.dart';
import '../../data/model/recent_search_query.dart';
import '../../domain/get_recent_search_queries_use_case.dart';
import '../../utils/command.dart';
import '../../utils/result.dart';

class SearchViewModel extends ChangeNotifier {
  SearchViewModel({
    required GetRecentSearchQueriesUseCase getRecentSearchQueriesUseCase,
    //required GetSearchContentsUseCase getSearchContentsUseCase,
    required RecentSearchQueryRepository recentSearchQueryRepository,
    required SearchContentsRepository searchContentsRepository,
    required SearchSuggestRepository searchSuggestRepository,
    String? initialQuery,
  }) : _recentSearchQueryRepository = recentSearchQueryRepository,
       _searchContentsRepository = searchContentsRepository,
       _searchSuggestRepository = searchSuggestRepository,
       _currentQuery = initialQuery {
    recentSearchQueries = getRecentSearchQueriesUseCase.invoke();
  }
  
  final _log = Logger('SearchViewModel');
  late final RecentSearchQueryRepository _recentSearchQueryRepository;
  late final SearchContentsRepository _searchContentsRepository;
  late final SearchSuggestRepository _searchSuggestRepository;

  String? _currentQuery;
  Iterable<String> _suggests = [];
  
  late final Stream<List<RecentSearchQuery>> recentSearchQueries;
  final searchController = SearchController();

  FutureOr<Iterable<String>> getSuggests(String query) async {
    if (_currentQuery != query) {
      await _debounceLoadSuggests(_currentQuery!);
    }
    return _suggests;
  }
  
  void init() {
    if (_currentQuery != null) {
      _loadSearchResult(_currentQuery!);
      searchController.text = _currentQuery!;
    } else {
      searchController.openView();
    }
  }
  
  void clearSearch() {
    searchController.clear();
  }
  
  void onSearchTriggered(String query) {
    if (query.trim().isEmpty) {
      return;
    }
    _recentSearchQueryRepository.insertOrReplaceRecentSearch(query);
    if (searchController.isOpen) {
      searchController.closeView(query);
    }
    //_loadSearchResult(query);
  }
  
  Future<void> _loadSearchResult(String query) async {}
  
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
  
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

enum DatePickerShowState {
  dismiss,
  selectStartDate,
  selectEndDate;
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

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../bili/constonts/constonts.dart';
import '../../data/repository/search/search_repository.dart';
import '../../data/repository/search_suggest/search_suggest_repository.dart';
import '../../utils/command.dart';
import '../../utils/result.dart';

class SearchViewModel extends ChangeNotifier {
  SearchViewModel({
    required SearchRepository searchRepository,
    required SearchSuggestRepository searchSuggestRepository,
    String? initialQuery,
  }) : _searchRepository = searchRepository,
       _searchSuggestRepository = searchSuggestRepository,
       _currentQuery = initialQuery;
  
  final _logger  = Logger();
  String? _currentQuery;
  //String? get currentQuery => _currentQuery;

  late final SearchRepository _searchRepository;
  late final SearchSuggestRepository _searchSuggestRepository;
  
  final _searchController = SearchController();
  get searchController => _searchController;
  
  Iterable<String> _suggests = [];
  

  DateTime _startTime = Constonts.minDate;
  DateTime get startTime => _startTime;

  DateTime _endTime = DateTime.now();
  DateTime get endTime => _endTime;
  
  void init() {
    if (_currentQuery != null) {
      _loadSearchResult(_currentQuery!);
      _searchController.text = _currentQuery!;
    } else {
      _searchController.openView();
    }
  }
  
  Future<Iterable<String>> getSuggests(String query) async {
    if (_currentQuery == query) {
      return _suggests;
    }
    _currentQuery = query;
    await _debounceLoadSuggests(_currentQuery!);
    if (_currentQuery == query) {
      return _suggests;
    }
    return [];
  }
  
  void onSearchTriggered(String query) {
    if (_searchController.isOpen) {
      _loadSearchResult(query);
      _searchController.closeView(query);
    }
  }
  
  Future<void> _loadSearchResult(String query) async {}
  
  late final _debounceLoadSuggests = _debounce<void, String>(_loadSuggests);

  Future<void> _loadSuggests(String query) async {
    _logger.d('Load suggests');
    final result = await _searchSuggestRepository.getSuggests(query);
    switch (result) {
      case Ok(:final value):
        _logger.d('Suggests (${value.length}) loaded');
        _suggests = value;
      case Error():
        _logger.w('Failed to load suggests', error: result.error);
        _suggests = [];
    }
  }

  void setStartTime(DateTime time) {
    _startTime = time;
    notifyListeners();
  }

  void setEndTime(DateTime time) {
    _endTime = time;
    notifyListeners();
  }
  
  void selectStartDate() {
    
  }
  
  void selectEndDate() {
    
  }
  
  void clearSearch() {
    _searchController.clear();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
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

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../bili/constonts/constonts.dart';
import '../../data/repository/search/search_repository.dart';
import '../../data/repository/search/search_suggest_repository.dart';
import '../../utils/command.dart';
import '../../utils/result.dart';

class SearchViewModel extends ChangeNotifier {
  SearchViewModel({
    required SearchRepository searchRepository,
    required SearchSuggestRepository searchSuggestRepository,
    String? initialQuery,
  }) : _searchRepository = searchSuggestRepository,
       _searchSuggestRepository = searchSuggestRepository {
    if (initialQuery != null && initialQuery.trim().isNotEmpty) {
      _searchController.text = initialQuery;
    } else {
      _searchController.openView();
    }
    
  }
  
  final _log = Logger('SearchViewModel');
  String? _currentQuery;

  late final SearchRepository _searchRepository;
  late final SearchSuggestRepository _searchSuggestRepository;
  
  final _searchController = SearchController();
  get searchController => _searchController;
  
  Iterable<String> _suggests = [];
  
  late final _debounceLoadSuggests = _debounce<void, String>(_loadSuggests);

  DateTime _startTime = Constonts.minDate;
  DateTime get startTime => _startTime;

  DateTime _endTime = DateTime.now();
  DateTime get endTime => _endTime;
  
  Iterable<String> getSuggests() {
    if (_currentQuery != _searchController.text) {
      return _suggests;
    }
    _currentQuery = _searchController.text;
    _debounceLoadSuggests(_currentQuery);
    return [];
  }
  
  void onSearchTriggered(String query) {
    
  }
  
  void onSuggestClick(String suggest) {
    onSearchTriggered(suggest);
    _controller.closeView(suggest);
  }
  
  Future<void> _loadSuggests(String query) async {
    final result = await _searchSuggestRepository.getSuggests(query);
    switch (result) {
      case Ok(:value):
        _log.fine('Suggests (${value.length}) loaded');
        if (query == _searchController.text) {
          _suggests = value;
          notifyListeners();
        }
      case Error(:error):
        _log.warning('Failed to load suggests', error);
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

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
  String get currentQuery => _currentQuery;
  
  late final SearchRepository _searchRepository;
  late final SearchSuggestRepository _searchSuggestRepository;
  
  final _searchController = SearchController();
  get searchController => _searchController;
  
  <List<String>> _suggests = [];
  get suggests => _suggests;
  
  late final _debounceLoadSuggests = _debounce<Iterable<String>?, String>(_loadSuggests);

  DateTime _startTime = Constonts.minDate;
  DateTime get startTime => _startTime;

  DateTime _endTime = DateTime.now();
  DateTime get endTime => _endTime;
  
  void onChanged() {
    _suggests = [];
    notifyListeners();
    _debounceLoadSuggests(_searchController.text);
  }
  
  void onSearchTriggered() {
    
  }
  
  void onSuggestClick(String suggest) {
    controller.closeView(suggest);
    onSearchTriggered();
  }
  
  Future<Result<void>> _loadSuggests(String query) async {
    final result = await _searchSuggestRepository.getSuggests(query);
    switch (result) {
      case Ok(:value):
        _log.fine('Suggests (${value.length}) loaded');
        if (query == _searchController.text) {
          _suggests = value;
          notifyListeners();
        }
      case Error():
        _log.warning('Failed to load suggests', result.error);
    }
    return result;
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
  
  void onChanged(String value) {
    
  }
  
  void onSearchTriggered(String value) {
    _searchController.closeView(value);
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


import 'dart:async';

import 'package:flutter/material.dart';


const Duration fakeAPIDuration = Duration(seconds: 1);
const Duration debounceDuration = Duration(milliseconds: 500);

void main() => runApp(const SearchAnchorAsyncExampleApp());

class SearchAnchorAsyncExampleApp extends StatelessWidget {
  const SearchAnchorAsyncExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('SearchAnchor - async and debouncing'),
        ),
        body: const Center(child: _AsyncSearchAnchor()),
      ),
    );
  }
}

class _AsyncSearchAnchor extends StatefulWidget {
  const _AsyncSearchAnchor();

  @override
  State<_AsyncSearchAnchor> createState() => _AsyncSearchAnchorState();
}

class _AsyncSearchAnchorState extends State<_AsyncSearchAnchor> {
  String? _currentQuery;

  late Iterable<Widget> _lastOptions = <Widget>[];

  late final _Debounceable<Iterable<String>?, String> _debouncedSearch;

  Future<Iterable<String>?> _search(String query) async {
    _currentQuery = query;

    final Iterable<String> options = await _FakeAPI.search(_currentQuery!);

    if (_currentQuery != query) {
      return null;
    }
    _currentQuery = null;

    return options;
  }

  @override
  void initState() {
    super.initState();
    _debouncedSearch = _debounce<Iterable<String>?, String>(_search);
  }

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      builder: (BuildContext context, SearchController controller) {
        return IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            controller.openView();
          },
        );
      },
      suggestionsBuilder:
          (BuildContext context, SearchController controller) async {
            final List<String>? options = (await _debouncedSearch(
              controller.text,
            ))?.toList();
            if (options == null) {
              return _lastOptions;
            }
            _lastOptions = List<ListTile>.generate(options.length, (int index) {
              final String item = options[index];
              return ListTile(
                title: Text(item),
                onTap: () {
                  debugPrint('You just selected $item');
                },
              );
            });

            return _lastOptions;
          },
    );
  }
}

// Mimics a remote API.
class _FakeAPI {
  static const List<String> _kOptions = <String>[
    'aardvark',
    'bobcat',
    'chameleon',
  ];

  // Searches the options, but injects a fake "network" delay.
  static Future<Iterable<String>> search(String query) async {
    await Future<void>.delayed(fakeAPIDuration); // Fake 1 second delay.
    if (query == '') {
      return const Iterable<String>.empty();
    }
    return _kOptions.where((String option) {
      return option.contains(query.toLowerCase());
    });
  }
}

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

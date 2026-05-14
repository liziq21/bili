import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/model/recent_search_query.dart';

/*
class AppSearchAnchor extends StatelessWidget {
  const AppSearchAnchor({
    super.key,
    required this.viewModel,
    this.navigateToSearchResult,
    this.builder,
  });

  final SearchAnchorChildBuilder? builder;
  final AppSearchAnchorViewModel viewModel;
  final Function(String)? navigateToSearchResult;

  void _handleSearch(String query) {
    viewModel.updateRecentSearch(query);
    navigateToSearchResult?.call(query);
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      descendantsAreFocusable: false,
      child: builder == null
          ? SearchAnchor.bar(
              barHintText: '搜索...',
              barElevation: .all(0.0),
              suggestionsBuilder: (_, controller) =>
                  _getSuggestions(controller),
              textInputAction: .search,
              onSubmitted: _handleSearch,
            )
          : SearchAnchor(
              builder: builder!,
              suggestionsBuilder: (_, controller) =>
                  _getSuggestions(controller),
              textInputAction: .search,
              viewOnSubmitted: _handleSearch,
            ),
    );
  }

  Future<List<Widget>> _getSuggestions(SearchController controller) async {
    if (controller.text.isEmpty) {
      if (viewModel.recentSearchQueries.isEmpty) {
        return <Widget>[
          const Center(
            child: Text(
              'No search history.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ];
      } else {
        return <Widget>[
          for (final RecentSearchQuery(:query) in viewModel.recentSearchQueries)
            ListTile(
              titleAlignment: ListTileTitleAlignment.center,
              leading: const Icon(Icons.history),
              title: Text(query),
              onTap: () => _handleSearch(query),
              trailing: IconButton(
                icon: const Icon(Icons.north_west),
                onPressed: () => controller.text = query,
              ),
            ),
        ];
      }
    }

    final _currentQuery = controller.text;
    final suggests = await viewModel.getSuggests(_currentQuery);

    return <Widget>[
      if (_currentQuery == controller.text || suggests.isNotEmpty)
        for (final suggest in suggests)
          ListTile(
            titleAlignment: ListTileTitleAlignment.center,
            leading: const Icon(Icons.public),
            title: Text(suggest),
            onTap: () {
              _handleSearch(suggest);
            },
            trailing: IconButton(
              icon: const Icon(Icons.north_west),
              onPressed: () => controller.text = suggest,
            ),
          ),
    ];
  }
}
*/
class AppSearchAnchor extends StatefulWidget {
  const AppSearchAnchor({
    super.key,
    required this.recentSearchStream, // 持续监听外部变化
    required this.fetchSuggests, // 搜索建议回调
    required this.onSearch, // 执行搜索（通常用于插入数据库）
    this.navigateToSearchResult,
    this.builder,
  });

  final SearchAnchorChildBuilder? builder;
  final Stream<List<RecentSearchQuery>> recentSearchStream;
  final Future<Iterable<String>> Function(String query) fetchSuggests;
  final void Function(String query) onSearch;
  final Function(String)? navigateToSearchResult;

  @override
  State<AppSearchAnchor> createState() => _AppSearchAnchorState();
}

class _AppSearchAnchorState extends State<AppSearchAnchor> {
  final SearchController _controller = SearchController();

  // 核心：在内存中维护一份最新的历史记录副本
  List<RecentSearchQuery> _currentHistory = [];
  StreamSubscription<List<RecentSearchQuery>>? _historySubscription;

  // 保持你原有的防抖实现（需确保 _debounce 函数在作用域内）
  late final _debouncedGetSuggests = _debounce<Iterable<String>, String>(
    widget.fetchSuggests,
  );

  @override
  void initState() {
    super.initState();
    // 1. 初始化时订阅流，确保他处修改时本组件能感知
    _historySubscription = widget.recentSearchStream.listen((data) {
      if (mounted) {
        setState(() {
          _currentHistory = data;
        });
      }
    });
  }

  @override
  void dispose() {
    // 2. 必须取消订阅
    _historySubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    if (query.isEmpty) return;
    widget.onSearch(query);
    widget.navigateToSearchResult?.call(query);
    _controller.closeView(query); // 搜索后关闭建议视图
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      descendantsAreFocusable: false,
      child: widget.builder == null
          ? SearchAnchor.bar(
              searchController: _controller,
              barHintText: '搜索...',
              barElevation: const WidgetStatePropertyAll(0.0),
              suggestionsBuilder: (_, _) => _getSuggestions(),
              textInputAction: TextInputAction.search,
              onSubmitted: _handleSearch,
            )
          : SearchAnchor(
              searchController: _controller,
              builder: widget.builder!,
              suggestionsBuilder: (_, _) => _getSuggestions(),
              textInputAction: TextInputAction.search,
              viewOnSubmitted: _handleSearch,
            ),
    );
  }

  Future<Iterable<Widget>> _getSuggestions() async {
    final text = _controller.text;

    // 3. 当输入为空时，直接使用内存中同步的最新历史记录
    if (text.isEmpty) {
      return _buildHistoryList(_currentHistory);
    }

    // 4. 当有输入时，调用带防抖的建议获取逻辑
    final suggests = await _debouncedGetSuggests(text);

    // 如果请求由于防抖被取消（返回null）或结果为空，则不更新 UI 或显示空
    if (suggests == null && text != _controller.text) return const [];

    return suggests!.map(
      (suggest) => ListTile(
        leading: const Icon(Icons.public),
        title: Text(suggest),
        onTap: () => _handleSearch(suggest),
        trailing: IconButton(
          icon: const Icon(Icons.north_west),
          onPressed: () => _controller.text = suggest,
        ),
      ),
    );
  }

  Iterable<Widget> _buildHistoryList(List<RecentSearchQuery> queries) {
    if (queries.isEmpty) {
      return const [
        Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'No search history.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ];
    }
    return queries.map(
      (item) => ListTile(
        leading: const Icon(Icons.history),
        title: Text(item.query),
        onTap: () => _handleSearch(item.query),
        trailing: IconButton(
          icon: const Icon(Icons.north_west),
          onPressed: () => _controller.text = item.query,
        ),
      ),
    );
  }
}

// 保持你提供的防抖逻辑不变
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
    _timer = Timer(const Duration(milliseconds: 300), _onComplete);
  }
  late final Timer _timer;
  final Completer<void> _completer = Completer<void>();
  void _onComplete() => _completer.complete();
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

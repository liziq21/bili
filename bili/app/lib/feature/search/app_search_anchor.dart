import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/model/recent_search_query.dart';
import 'bloc/search_bloc.dart';

class const AppSearchAnchor({
  super.key,
  required final void Function(String query) onSearch, // 执行搜索（通常用于插入数据库）
  final List<RecentSearchQuery> recentSearchQuery = const [],
  final Function(String)? navigateToSearchResult,
  final SearchAnchorChildBuilder? builder,
}) extends StatefulWidget {
  @override
  State<AppSearchAnchor> createState() => _AppSearchAnchorState();
}

class _AppSearchAnchorState extends State<AppSearchAnchor> {
  final SearchController _controller = SearchController();
  String? _searchingWithQuery;
  late Iterable<Widget> _lastOptions = <Widget>[];
  @override
  void dispose() {
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
      child: BlocSelector<SearchBloc, SearchState, List<RecentSearchQuery>>(
        selector: (state) => state.recentSearchQueries,
        builder: (_, state) {
          return widget.builder == null
              ? SearchAnchor.bar(
                  searchController: _controller,
                  barHintText: '搜索...',
                  barElevation: const WidgetStatePropertyAll(0.0),
                  suggestionsBuilder: _getSuggestions,
                  textInputAction: .search,
                  onSubmitted: _handleSearch,
                )
              : SearchAnchor(
                  searchController: _controller,
                  builder: widget.builder!,
                  suggestionsBuilder: _getSuggestions,
                  textInputAction: .search,
                  viewOnSubmitted: _handleSearch,
                );
        },
      ),
    );
  }

  Future<Iterable<Widget>> _getSuggestions(
    BuildContext context,
    SearchController controller,
  ) async {
    _searchingWithQuery = controller.text;

    // if (_searchingWithQuery!.isEmpty) {
    //   return _buildHistoryList(widget.recentSearchQuery);
    // }

    final bloc = context.read<SearchBloc>()
      ..add(SearchQueryChanged(_searchingWithQuery!));

    final options = (await bloc.stream.first).suggests;

    if (_searchingWithQuery != controller.text) return _lastOptions;

    _lastOptions = List.generate(options.length, ((index) {
      final item = options[index];

      return ListTile(
        leading: const Icon(Icons.public),
        title: Text(item),
        onTap: () => _handleSearch(item),
        trailing: IconButton(
          icon: const Icon(Icons.north_west),
          onPressed: () => _controller.text = item,
        ),
      );
    }));
    return _lastOptions;
  }

  // Iterable<Widget> _buildHistoryList(List<RecentSearchQuery> queries) {
  //   if (queries.isEmpty) {
  //     return const [
  //       Center(
  //         child: Padding(
  //           padding: EdgeInsets.all(24.0),
  //           child: Text(
  //             'No search history.',
  //             style: TextStyle(color: Colors.grey),
  //           ),
  //         ),
  //       ),
  //     ];
  //   }
  //   return queries.map(
  //     (item) => ListTile(
  //       leading: const Icon(Icons.history),
  //       title: Text(item.query),
  //       onTap: () => _handleSearch(item.query),
  //       trailing: IconButton(
  //         icon: const Icon(Icons.north_west),
  //         onPressed: () => _controller.text = item.query,
  //       ),
  //     ),
  //   );
  // }
}

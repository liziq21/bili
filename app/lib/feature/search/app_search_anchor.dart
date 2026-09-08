import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/model/recent_search_query.dart';
import 'bloc/search_bloc.dart';

class AppSearchAnchor extends StatefulWidget {
  const AppSearchAnchor({
    super.key,
    required this.onSearch,
    this.recentSearchQuery = const [],
    this.navigateToSearchResult,
    this.builder,
  });

  final void Function(String query) onSearch;
  final List<RecentSearchQuery> recentSearchQuery;
  final Function(String)? navigateToSearchResult;
  final SearchAnchorChildBuilder? builder;

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
    _controller.closeView(query);
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
                  textInputAction: TextInputAction.search,
                  onSubmitted: _handleSearch,
                )
              : SearchAnchor(
                  searchController: _controller,
                  builder: widget.builder!,
                  suggestionsBuilder: _getSuggestions,
                  textInputAction: TextInputAction.search,
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

    final bloc = context.read<SearchBloc>()
      ..add(SearchQueryChanged(_searchingWithQuery!));

    final options = (await bloc.stream.first).suggests;

    if (_searchingWithQuery != controller.text) return _lastOptions;

    _lastOptions = List.generate(options.length, (index) {
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
    });
    return _lastOptions;
  }
}

import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/model/recent_search_query.dart';
import 'app_search_anchor_view_model.dart';

class AppSearchAnchor extends StatelessWidget {
  const AppSearchAnchor({
    super.key,
    required this.viewModel,
    this.onSearchTriggerrid,
    this.builder,
  });

  final SearchAnchorChildBuilder? builder;
  final AppSearchAnchorViewModel viewModel;
  final Function(String)? onSearchTriggerrid;

  void _handleSearch(String query) {
    viewModel.updateRecentSearch(query);
    onSearchTriggerrid?.call(query);
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

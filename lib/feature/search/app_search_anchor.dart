import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../bili/search_type.dart';
import '../../data/model/recent_search_query.dart';
import 'app_search_anchor_view_model.dart';

class AppSearchAnchor extends StatefulWidget {
  const AppSearchAnchor({
    super.key,
    required this.viewModel,
    this.onSearch,
    this.builder,
  });
  
  final SearchAnchorChildBuilder? builder;
  final AppSearchAnchorViewModel viewModel;
  final ValueCallback<String>? onSearch;

  @override
  State<AppSearchAnchor> createState() => _AppSearchAnchor();
}

class _AppSearchAnchorState extends State<AppSearchAnchor> {
  final _log = Logger('_AppSearchAnchorState');
  List<RecentSearchQuery> _recentSearchQueries = [];
  StreamSubscription<List<RecentSearchQuery>>? _recentSearchQuerySubscription;
  
  @override
  void initState() {
    super.initState();
    _recentSearchQuerySubscription = widget.viewModel.recentSearchQueries.listen(
      (data) {
        _log.fine('RecentSearchQuery loaded');
        setState(() => _recentSearchQueries = data);
      },
      onError: (e) => _log.warning('Error loading RecentSearchQuery: $e'),
    );
  }
  
  @override
  void dispose() {
    _recentSearchQuerySubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FocusScope(
      descendantsAreFocusable: false,
      child: widget.builder == null
        ? SearchAnchor.bar(
          barHintText: '搜索...',
          barElevation: .all(0.0),
          suggestionsBuilder: (_, controller) => _getSuggestions(controller),
          textInputAction: .search,
          onSubmitted: (query) {
            if (query.trim().isNotEmpty) {
              widget.viewModel.insertOrReplaceRecentSearch(query);
              widget.onSearch(query);
            }
          },
        )
        : SearchAnchor(
          builder: widget.builder!,
          suggestionsBuilder: (_, controller) => _getSuggestions(controller),
          textInputAction: .search,
          viewOnSubmitted: (query) {
            if (query.trim().isNotEmpty) {
              widget.viewModel.insertOrReplaceRecentSearch(query);
              widget.onSearch(query);
            }
          },
        ),
    ),
  }
  
  Future<L<Widget>> _getSuggestions(TextEditingController controller) async {
    if (controller.text.isEmpty) {
      return <Widget>[
        Center(
          child: Text(
            'No search history.',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ];
    } else {
      return <Widget>[
        for (final RecentSearchQuery(:query) in _recentSearchQueries)
          ListTile(
            titleAlignment: ListTileTitleAlignment.center,
            leading: const Icon(Icons.history),
            title: Text(query),
              onTap: () {
                widget.viewModel.insertOrReplaceRecentSearch(query);
                controller.closeView(query);
                widget.onSearch(suggest);
              },
              trailing: IconButton(
              icon: const Icon(Icons.north_west),
              onPressed: () => controller.text = query,
            ),
          ),
      ];
    }
    
    final _currentQuery = controller.text;
    final suggests = await widget.viewModel.getSuggests(_currentQuery);
    
    return <Widget>[
      if (_currentQuery == controller.text || suggests.isNotEmpty)
        for (final suggest in suggests)
          ListTile(
            titleAlignment: ListTileTitleAlignment.center,
            leading: const Icon(Icons.public),
            title: Text(suggest),
            onTap: () {
              widget.viewModel.insertOrReplaceRecentSearch(query);
              controller.closeView(query);
              widget.onSearch(suggest);
            },
            trailing: IconButton(
              icon: const Icon(Icons.north_west),
              onPressed: () => controller.text = suggest,
            ),
          ),
    ];
  }
}

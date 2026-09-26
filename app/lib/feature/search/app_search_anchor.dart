import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/model/recent_search_query.dart';
import 'bloc/search_bloc.dart';

class const AppSearchAnchor({
  super.key,
  required final void Function(String query) onSearch, // 执行搜索（通常用于插入数据库）
  final List<RecentSearchQuery> recentSearchQuery = const [],
  final Function(String)? navigateToSearchResult,
  final SearchAnchorChildBuilder? builder,

  /// 搜索关键词的最大长度。SearchAnchor 的 SearchBar 没有暴露 maxLength，
  /// 这里在 viewOnChanged 里截断，等价于旧 TextField 的
  /// [MaxLengthEnforcement.enforced]。
  final int maxQueryLength = 200,
}) extends StatefulWidget {
  @override
  State<AppSearchAnchor> createState() => _AppSearchAnchorState();
}

class _AppSearchAnchorState() extends State<AppSearchAnchor> {
  final SearchController _controller = SearchController();
  String? _searchingWithQuery;
  late Iterable<Widget> _lastOptions = <Widget>[];

  /// [SearchAnchor] 把建议浮层作为一条路由推进最近的 [Navigator]，该路由挂在
  /// Navigator 的 overlay 上，位于本路由子树之外，因此在浮层里
  /// `context.read<SearchBloc>()` 只会得到 null 或直接抛
  /// [ProviderNotFoundException]。这里在 anchor 一侧（bloc 可见处）抓住实例，
  /// 供浮层回调使用。
  SearchBloc? _searchBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _searchBloc = context.read<SearchBloc?>();
  }

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

  /// 把超长输入截断回 [AppSearchAnchor.maxQueryLength]。
  void _handleViewChanged(String value) {
    final limit = widget.maxQueryLength;
    if (limit > 0 && value.length > limit) {
      _controller.text = value.substring(0, limit);
    }
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
                  onChanged: _handleViewChanged,
                )
              : SearchAnchor(
                  searchController: _controller,
                  builder: widget.builder!,
                  suggestionsBuilder: _getSuggestions,
                  textInputAction: .search,
                  viewOnSubmitted: _handleSearch,
                  viewOnChanged: _handleViewChanged,
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

    final bloc = _searchBloc;
    if (bloc == null || bloc.isClosed) return _lastOptions;

    // bloc 在等待期间可能被关闭（用户提交或直接离开搜索页），此时
    // `stream.first` 会抛 `Bad state: No element`，直接吃掉返回上一次结果。
    List<String> options;
    try {
      bloc.add(SearchQueryChanged(_searchingWithQuery!));
      options = (await bloc.stream.first).suggests;
    } on StateError {
      return _lastOptions;
    }

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

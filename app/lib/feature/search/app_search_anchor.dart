import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/model/recent_search_query.dart';
import 'bloc/search_bloc.dart';

class const AppSearchAnchor({
  super.key,
  required final void Function(String query) onSearch,
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

/// 等待建议状态的上限。firstWhere 需要 currentQuery 精确匹配，若该查询被
/// debounce 合并掉就永远等不到，因此必须兜一个超时而不是无限期挂起。
const Duration _suggestionTimeout = Duration(seconds: 5);

class _AppSearchAnchorState() extends State<AppSearchAnchor> {
  final SearchController _controller = SearchController();
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
  ///
  /// SearchBar 没有暴露 `inputFormatters`，只能在 `viewOnChanged` 里回写。
  /// 用 SDK 的 [LengthLimitingTextInputFormatter] 而不是
  /// `value.substring(0, limit)`：后者按 UTF-16 code unit 切，会把 emoji 的
  /// 代理对劈成半个字符，而且经由 `.text` 赋值会丢掉选区和输入法 composing
  /// 状态（中文输入法的候选窗会因此跳字）。
  ///
  /// 走 `formatEditUpdate` 而不是 SDK 内部的 `truncate` 静态方法——后者标了
  /// `@visibleForTesting`。显式传 `enforced`：默认值在 linux 桌面上是
  /// `truncateAfterCompositionEnds`，会让 composing 期间的输入突破上限。
  void _handleViewChanged(String value) => _enforceMaxQueryLength();

  /// 把 controller 里的文本截回 [AppSearchAnchor.maxQueryLength]。
  void _enforceMaxQueryLength() {
    final limit = widget.maxQueryLength;
    if (limit <= 0) return;

    final current = _controller.value;
    if (current.text.characters.length <= limit) return;

    // oldValue 传空值：这里的语义是「本次编辑的结果超限了，截断它」，
    // 而不是「已到上限还想再加」——后者会把用户正在输的最后一个字弹回去。
    _controller.value = LengthLimitingTextInputFormatter(
      limit,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
    ).formatEditUpdate(const TextEditingValue(), current);
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SearchBloc, SearchState, List<RecentSearchQuery>>(
      selector: (state) => state.recentSearchQueries,
      builder: (_, state) {
        final anchor = widget.builder == null
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

        // bar 模式自带一个 TextField，用 descendantsAreFocusable: false 避免
        // 它参与外层 Tab 序列。图标模式相反——那个 IconButton 必须能被键盘
        // 聚焦，否则纯键盘用户根本打不开搜索。
        return widget.builder == null
            ? FocusScope(descendantsAreFocusable: false, child: anchor)
            : anchor;
      },
    );
  }

  Future<Iterable<Widget>> _getSuggestions(
    BuildContext context,
    SearchController controller,
  ) async {
    // SearchAnchor.bar 没有 viewOnChanged（material_ui 1.4.0 的 API 缺口），
    // 它打开的浮层是另一个 TextField，只接 bar 自己的 onChanged 拦不住。
    // suggestionsBuilder 是两种模式浮层输入的共同路径，所以在这里兜底。
    _enforceMaxQueryLength();

    final query = controller.text;

    // if (_searchingWithQuery!.isEmpty) {
    //   return _buildHistoryList(widget.recentSearchQuery);
    // }

    final bloc = _searchBloc;
    if (bloc == null || bloc.isClosed) return _lastOptions;

    // bloc 在等待期间可能被关闭（用户提交或直接离开搜索页），此时
    // `stream.first` 会抛 `Bad state: No element`，直接吃掉返回上一次结果。
    //
    // 只接受 currentQuery 与本次查询一致的状态：switchMap 取消的是订阅，
    // 不是已经 in-flight 的 getSuggests，那次请求完成后 emit 仍会进 stream，
    // 所以 stream.first 可能拿到属于上一个查询的 suggests。
    List<String> options;
    try {
      bloc.add(SearchQueryChanged(query));
      final state = await bloc.stream
          .firstWhere((s) => s.currentQuery == query)
          .timeout(_suggestionTimeout);
      options = state.suggests;
    } on StateError {
      return _lastOptions;
    } on TimeoutException {
      return _lastOptions;
    }

    // 等待期间用户可能又改了输入，此时这份结果已经过期。
    if (query != controller.text) return _lastOptions;

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

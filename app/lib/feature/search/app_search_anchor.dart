import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/model/recent_search_query.dart';
import '../../l10n/localization_file/app_localizations.dart';
import 'bloc/search_bloc.dart';

class const AppSearchAnchor({
  super.key,
  required final void Function(String query) onSearch,
  final List<RecentSearchQuery> recentSearchQuery = const [],
  final Function(String)? navigateToSearchResult,
  final SearchAnchorChildBuilder? builder,

  /// 最近搜索最多展示的条数。
  final int recentQueryLimit = 20,

  /// 删除单条搜索历史的回调。为 null 时不展示删除入口。
  ///
  /// 由页面注入：浮层是挂到 Navigator overlay 上的一条路由，位于本组件的
  /// provider 子树之外，所以在浮层里读 `context.read` 拿不到仓库。
  final void Function(String query)? onDeleteRecentSearch,

  /// 清空全部搜索历史的回调。为 null 时不展示「清空」入口。
  final void Function()? onClearRecentSearch,

  /// 登记聚焦入口的回调，由本组件在挂载时以 `focusInput` 调用、销毁时以 null 调用
  ///
  /// 外部（底栏导航的搜索目的地）需要在「已在搜索页又点一次搜索」时把焦点移回
  /// 输入框。bar 模式的输入框由 `SearchBar` 自建焦点节点且 `SearchAnchor.bar`
  /// 不透传 `focusNode`，外部拿不到那个节点，所以只能由本组件自己暴露入口。
  /// 为 null 时不注册，组件内部仍照常工作。
  final void Function(void Function()? focus)? onFocusInputReady,

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

/// 把建议词与历史记录合并成一份去重后的建议列表。
///
/// 历史记在 [history] 里（通常按时间倒序），建议词来自远端按相关度排序。
/// 合并规则：
///
/// 1. 当前输入 [query] 本身不进入结果——它已经在输入框里，再列一条没有意义；
/// 2. 建议词在前，历史在后，各自保持原有顺序；
/// 3. 按「忽略大小写 + 去掉首尾空白」判重，先出现的赢，且输出的是先出现的
///    那一份原文，不会因为后出现的写法不同而改变大小写。
///
/// 纯函数，便于对去重规则单测，也避免把这条规则埋在两个 widget 的构造顺序里。
List<String> mergeSuggestions({
  required String query,
  required Iterable<String> suggests,
  required Iterable<RecentSearchQuery> history,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final seen = <String>{};
  final merged = <String>[];

  void add(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return;
    final key = value.toLowerCase();
    if (key == normalizedQuery) return;
    if (!seen.add(key)) return;
    merged.add(value);
  }

  for (final suggest in suggests) {
    add(suggest);
  }
  for (final item in history) {
    add(item.query);
  }
  return merged;
}

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
  void initState() {
    super.initState();
    // 只在注册与注销之间持有回调：外部可能在 dispose 之后仍持有它，
    // 那时调用会打到已销毁的 controller。
    widget.onFocusInputReady?.call(focusInput);
  }

  @override
  void didUpdateWidget(AppSearchAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onFocusInputReady != widget.onFocusInputReady) {
      oldWidget.onFocusInputReady?.call(null);
      widget.onFocusInputReady?.call(focusInput);
    }
  }

  @override
  void dispose() {
    widget.onFocusInputReady?.call(null);
    _controller.dispose();
    super.dispose();
  }

  /// 把焦点交回搜索输入框。
  ///
  /// bar 模式下输入框由 [SearchBar] 自建焦点节点，`SearchAnchor.bar` 不透传
  /// `focusNode`，外部拿不到那个节点。可用的入口只有 [SearchController.openView]：
  /// 它推进搜索视图路由，视图内的输入框会自行获得焦点（material_ui 的
  /// `_SearchPageState` 在路由就位后请求焦点）。若搜索视图已处于打开状态
  /// （[_controller.isOpen] 为 true），直接返回以防止重复推入新的视图路由。
  void focusInput() {
    if (!_controller.isAttached) return;
    if (_controller.isOpen) return;
    _controller.openView();
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
    // ⚡ Bolt Optimization: Build SearchAnchor directly without wrapping in a BlocSelector.
    // SearchAnchor UI does not depend on recent search query state emissions. Suggestions
    // subscribe directly to SearchBloc via stream listeners in _getSuggestions, avoiding
    // unnecessary rebuild passes of the SearchAnchor and FocusScope subtrees whenever
    // recent search queries are added or updated in state.
    return _buildAnchor(context);
  }

  Widget _buildAnchor(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final anchor = widget.builder == null
        ? SearchAnchor.bar(
            searchController: _controller,
            barHintText: l10n?.searchHint ?? 'Search...',
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
    final history = _visibleHistory();

    // 输入为空时没有可联想的东西，浮层就是历史页：最近的搜索 + 清空入口。
    if (query.trim().isEmpty) {
      _lastOptions = [_buildHistoryList(context, history)];
      return _lastOptions;
    }

    final bloc = _searchBloc;
    if (bloc == null || bloc.isClosed) {
      // 数据源不支持建议时不发请求，但历史仍然要能点、能填回输入框。
      _lastOptions = [
        _buildSuggestionList(
          context,
          mergeSuggestions(query: query, suggests: const [], history: history),
          history: history,
        ),
      ];
      return _lastOptions;
    }

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

    // 浮层是挂在 overlay 上的路由，await 之后本组件可能已经销毁。此时不读
    // context，直接沿用上一次结果，避免对已卸载的 element 求 l10n/theme。
    if (!context.mounted || !mounted) return _lastOptions;

    _lastOptions = [
      _buildSuggestionList(
        context,
        mergeSuggestions(query: query, suggests: options, history: history),
        history: history,
      ),
    ];
    return _lastOptions;
  }

  /// 当前可展示的历史记录，按 [AppSearchAnchor.recentQueryLimit] 截断。
  List<RecentSearchQuery> _visibleHistory() {
    final all = widget.recentSearchQuery;
    final limit = widget.recentQueryLimit;
    if (limit <= 0) return all;
    return all.length <= limit ? all : all.sublist(0, limit);
  }

  /// 构造合并后的建议列表。
  ///
  /// 单条渲染同一个 [ListTile]：点击直接搜索，右侧按钮把词填回输入框。
  /// 历史项额外带长按删除（由 [AppSearchAnchor.onDeleteRecentSearch] 决定
  /// 是否存在），建议项没有——它不是用户留下的记录。
  Widget _buildSuggestionList(
    BuildContext context,
    List<String> items, {
    required List<RecentSearchQuery> history,
  }) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final historyKeys = {
      for (final item in history) item.query.trim().toLowerCase(),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                l10n?.nothingFound ?? 'Nothing found',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        for (final item in items)
          _buildTile(
            context: context,
            item: item,
            isHistory: historyKeys.contains(item.toLowerCase()),
          ),
      ],
    );
  }

  /// 只展示历史的浮层（输入为空，或数据源没有建议能力）。
  Widget _buildHistoryList(
    BuildContext context,
    List<RecentSearchQuery> history,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canClear = widget.onClearRecentSearch != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n?.recentSearches ?? 'Recent searches',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (canClear && history.isNotEmpty)
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.onClearRecentSearch?.call();
                  },
                  child: Text(
                    l10n?.clearAllSearchHistory ?? 'Clear all search history',
                  ),
                ),
            ],
          ),
        ),
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                l10n?.noSearchHistory ?? 'No search history yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          for (final item in history)
            _buildTile(context: context, item: item.query, isHistory: true),
      ],
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required String item,
    required bool isHistory,
  }) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canDelete = isHistory && widget.onDeleteRecentSearch != null;

    return ListTile(
      leading: Icon(
        isHistory ? Icons.history : Icons.public,
        color: isHistory ? theme.colorScheme.onSurfaceVariant : null,
      ),
      title: Text(item),
      onTap: () => _handleSearch(item),
      // 长按删除只对历史项开放。建议项不是用户留下的记录，删它没有语义。
      onLongPress: canDelete
          ? () {
              HapticFeedback.mediumImpact();
              widget.onDeleteRecentSearch?.call(item);
            }
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.north_west),
        // The tooltip names the suggestion it fills, so a screen-reader user
        // moving between rows can tell them apart. Wording stays inside the
        // golden font subset (app/test/fonts/subset-characters.txt); adding a
        // character outside it fails golden_font_contract_test.
        tooltip: l10n?.putIntoSearchBox(item),
        onPressed: () {
          HapticFeedback.lightImpact();
          _controller.text = item;
        },
      ),
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/repository/recent_search_query/recent_search_query_repository.dart';
import '../../data/repository/search_suggest_repository.dart';
import '../../main.dart';
import 'app_search_anchor.dart';
import 'bloc/search_bloc.dart';

/// 独立搜索页（底部导航第二项）
///
/// 本页只负责展示搜索框与最近搜索；提交关键词后交由 [onSearch] 跳转结果页。
/// 做成可直达的独立页面，而不是把 [AppSearchAnchor] 塞进首页 AppBar，是为了让
/// 底栏每个目的地都能被直接唤起（导航语义：点按当前项回到该分支根）。
class const SearchScreen({
  super.key,
  required this.onSearch,
  this.recentQueryLimit = 20,
}) extends StatelessWidget {
  final void Function(String query) onSearch;

  /// 最近搜索最多展示的条数
  final int recentQueryLimit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                $styles.insets.sm,
                $styles.insets.sm,
                $styles.insets.sm,
                0,
              ),
              sliver: SliverToBoxAdapter(child: _searchField(context)),
            ),
            _RecentSearches(limit: recentQueryLimit, onSearch: onSearch),
          ],
        ),
      ),
    );
  }

  Widget _searchField(BuildContext context) {
    // 建议能力依赖 SearchBloc 注入的 SearchSuggestRepository。数据源不支持
    // 建议时（provider 未注入）传空仓库，让输入与提交照常工作而不是抛
    // ProviderNotFoundException。
    final suggest = context.read<SearchSuggestRepository?>();
    // 最近搜索写入走 repository 而不是 SearchBloc：数据源不支持建议时
    // `_withSearchBloc` 不注入该 bloc（SearchBloc 的存在只为建议浮层），
    // 若把写入挂在 bloc 上，这条路径下的提交就永远不会被记录——而历史本身与
    // 建议能力无关。
    void recordAndSearch(String query) {
      final repository = context.read<RecentSearchQueryRepository?>();
      if (query.isNotEmpty) {
        repository?.insertOrReplaceRecentSearch(query);
      }
      onSearch(query);
    }

    if (suggest == null) {
      return AppSearchAnchor(
        onSearch: recordAndSearch,
        navigateToSearchResult: null,
      );
    }
    return AppSearchAnchor(
      onSearch: recordAndSearch,
      // 建议浮层选中一项时直接进结果页，同样要落历史。
      navigateToSearchResult: recordAndSearch,
    );
  }
}

/// 最近搜索列表
///
/// [SearchBloc] 通过 [MonitorRecentSearches] 订阅仓库的变更流，这里只渲染
/// 快照。bloc 缺失时（数据源不支持建议）整块不渲染。
class const _RecentSearches({
  required this.limit,
  required this.onSearch,
}) extends StatelessWidget {
  final int limit;
  final void Function(String query) onSearch;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SearchBloc?>();
    if (bloc == null) return const SliverToBoxAdapter();

    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        final queries = state.recentSearchQueries;
        if (queries.isEmpty) return const SliverToBoxAdapter();

        final theme = Theme.of(context);
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
            $styles.insets.sm,
            $styles.insets.md,
            $styles.insets.sm,
            $styles.insets.xl,
          ),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '最近搜索',
                      style: $styles.text.title2?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.read<SearchBloc>().add(
                      ClearRecentSearchesPressed(),
                    ),
                    child: const Text('清空'),
                  ),
                ],
              ),
              for (final q in queries.take(limit))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.history_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(q.query),
                  onTap: () => onSearch(q.query),
                ),
            ],
          ),
        );
      },
    );
  }
}

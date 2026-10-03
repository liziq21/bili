import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/model/recent_search_query.dart';
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
  required final void Function(String query) onSearch,
  final int recentQueryLimit = 20,
}) extends StatelessWidget {

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
    void record(String query) {
      if (query.isEmpty) return;
      final repository = context.read<RecentSearchQueryRepository?>();
      if (repository == null) return;
      // 不 await：搜索跳转不该等写库。但必须挂错误处理——写失败不该变成
      // 未处理的异步错误，把用户的检索动作一起带走。
      unawaited(
        repository.insertOrReplaceRecentSearch(query).onError((error, _) {
          // 历史只是辅助信息，记不上不该影响本次搜索。
        }),
      );
    }

    if (suggest == null) {
      return AppSearchAnchor(
        // 数据源无建议能力时 navigateToSearchResult 必须留空：
        // AppSearchAnchor._handleSearch 会把 onSearch 与 navigateToSearchResult
        // 两个都调一遍，两者指同一个函数就会跳两次结果页。
        onSearch: (query) {
          record(query);
          onSearch(query);
        },
      );
    }
    return AppSearchAnchor(
      // 有建议时走 navigateToSearchResult（它负责关闭浮层）。onSearch 留空：
      // 它与 navigateToSearchResult 在 _handleSearch 里都会被调一遍，
      // 给它一个真实现等于把同一次提交执行两次。
      onSearch: (_) {},
      navigateToSearchResult: (query) {
        record(query);
        onSearch(query);
      },
    );
  }
}

/// 最近搜索列表
///
/// [SearchBloc] 通过 [MonitorRecentSearches] 订阅仓库的变更流，这里只渲染
/// 快照。bloc 缺失时（数据源不支持建议）整块不渲染。
class const _RecentSearches({
  required final int limit,
  required final void Function(String query) onSearch,
}) extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SearchBloc?>();
    if (bloc == null) return const SliverToBoxAdapter();

    // ⚡ Bolt Optimization: Use BlocSelector to select only `recentSearchQueries`.
    // Rebuilding `_RecentSearches` strictly when search history changes isolates
    // this subtree from high-frequency typing/suggestion state updates (e.g. `currentQuery` or
    // `suggests` emissions) as users type into the search bar.
    return BlocSelector<
      SearchBloc,
      SearchState,
      List<RecentSearchQuery>
    >(
      selector: (state) => state.recentSearchQueries,
      builder: (context, queries) {
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
                      style: $styles.text.title2.copyWith(
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

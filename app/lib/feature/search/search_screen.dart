import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/repository/recent_search_query/recent_search_query_repository.dart';
import '../../data/repository/search_suggest_repository.dart';
import '../../main.dart';
import 'app_search_anchor.dart';
import 'bloc/search_bloc.dart';

/// 独立搜索页（底部导航第二项）
class const SearchScreen({
  super.key,
  required final void Function(String query) onSearch,

  /// 最近搜索最多展示的条数
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
    final suggest = context.read<SearchSuggestRepository?>();
    void record(String query) {
      if (query.isEmpty) return;
      final repository = context.read<RecentSearchQueryRepository?>();
      if (repository == null) return;
      unawaited(
        repository.insertOrReplaceRecentSearch(query).onError((error, _) {
          // 历史只是辅助信息，记不上不该影响本次搜索。
        }),
      );
    }

    if (suggest == null) {
      return AppSearchAnchor(
        onSearch: (query) {
          record(query);
          onSearch(query);
        },
      );
    }
    return AppSearchAnchor(
      onSearch: (_) {},
      navigateToSearchResult: (query) {
        record(query);
        onSearch(query);
      },
    );
  }
}

/// 最近搜索列表
class const _RecentSearches({
  required final int limit,
  required final void Function(String query) onSearch,
}) extends StatelessWidget {
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

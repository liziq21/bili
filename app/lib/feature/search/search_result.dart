import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';
import 'bloc/search_result_bloc.dart';

class const SearchResult<T>({
  super.key,
  required final ItemWidgetBuilder<T> itemBuilder,

  final double itemAspectRatio = 1.0,
  final double maxCrossAxisExtent = 200.0,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      SearchResultBloc<T>,
      SearchResultState<T>,
      PagingState<int, T>
    >(
      selector: (state) => state.pagingState,
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            PagedSliverGrid<int, T>(
              state: state,
              fetchNextPage: () => context.read<SearchResultBloc<T>>().add(
                const FetchNextPage(),
              ),
              builderDelegate: PagedChildBuilderDelegate(
                itemBuilder: itemBuilder,
                firstPageErrorIndicatorBuilder: (context) =>
                    _SearchErrorView<T>(),
                newPageErrorIndicatorBuilder: (context) =>
                    _NewPageErrorIndicator<T>(),
                noItemsFoundIndicatorBuilder: (context) =>
                    const _EmptySearchIndicator(),
              ),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: maxCrossAxisExtent,
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
                // 💡 放弃固定 mainAxisExtent，改用自适应比例
                childAspectRatio: itemAspectRatio,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 首页搜索失败视图：图标 + 提示文案 + 明确重试按钮 + 触觉反馈 + 屏幕阅读器语义
class const _SearchErrorView<T>({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
          SizedBox(height: $styles.insets.sm),
          Text(
            l10n?.loadFailedRetryLater ??
                'Load failed. Please try again later.',
            style: $styles.text.body.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: $styles.insets.xs),
          Semantics(
            button: true,
            label: l10n?.loadFailedRetry ?? 'Load failed. Retry.',
            excludeSemantics: true,
            child: TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.read<SearchResultBloc<T>>().add(const FetchNextPage());
              },
              child: Text(l10n?.retry ?? 'Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 翻页加载失败视图：单行可点击重试区域 + 触觉反馈 + 屏幕阅读器语义
class const _NewPageErrorIndicator<T>({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.all($styles.insets.sm),
      child: Center(
        child: Semantics(
          button: true,
          label: l10n?.moreLoadFailedRetry ?? 'Failed to load more. Retry.',
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular($styles.corners.sm),
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<SearchResultBloc<T>>().add(const FetchNextPage());
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: $styles.insets.sm,
                vertical: $styles.insets.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: colorScheme.error,
                  ),
                  SizedBox(width: $styles.insets.xs),
                  Text(
                    l10n?.moreLoadFailedRetry ?? 'Failed to load more. Retry.',
                    style: $styles.text.bodySmall.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 空搜索结果视图：图标 + 文字 + 屏幕阅读器整体语义
class const _EmptySearchIndicator() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Semantics(
        label: l10n?.nothingFound ?? 'Nothing found',
        excludeSemantics: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: colorScheme.outline,
            ),
            SizedBox(height: $styles.insets.xs),
            Text(
              l10n?.nothingFound ?? 'Nothing found',
              style: $styles.text.body.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

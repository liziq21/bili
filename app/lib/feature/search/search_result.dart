import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:material_ui/material_ui.dart';

import '../../design/design.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';
import '../../ui/common/rate_limit_retry.dart';
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
                firstPageErrorIndicatorBuilder: (context, error) =>
                    _SearchErrorView<T>(error: error),
                newPageErrorIndicatorBuilder: (context, error) =>
                    _NewPageErrorIndicator<T>(error: error),
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
///
/// 搜索的风控窗口里接口会返回 `code: 0` 但只有 `v_voucher`，服务包把它适配成
/// [RateLimitedFailure]；此时换成限流文案并让重试先冷静一段时间。
class const _SearchErrorView<T>({required final Object? error})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final rateLimited = isRateLimited(error);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.error, size: 48, color: colorScheme.error),
          SizedBox(height: $styles.insets.sm),
          Text(
            rateLimited
                ? l10n.rateLimitedRetryLater
                : l10n.loadFailedRetryLater,
            style: $styles.text.body.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: $styles.insets.xs),
          // 这里不包固定 label 的 Semantics：那会盖掉按钮自己的倒计时文案与
          // 禁用状态，读屏用户就听不到冷静期了。
          RetryCooldownButton(
            style: TextButton.styleFrom(),
            rateLimited: rateLimited,
            scope: 'search.first',
            failure: error,
            onRetry: () =>
                context.read<SearchResultBloc<T>>().add(const FetchNextPage()),
          ),
        ],
      ),
    );
  }
}

/// 翻页加载失败视图：单行可点击重试区域 + 触觉反馈 + 屏幕阅读器语义
class const _NewPageErrorIndicator<T>({required final Object? error})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rateLimited = isRateLimited(error);
    return Padding(
      padding: EdgeInsets.all($styles.insets.sm),
      child: Center(
        // 限流时也保留入口，只是先走冷却倒计时：分页失败后用户仍然要能接着
        // 往下翻，只是不能立刻重发同一个被拒的请求。
        child: RetryCooldownInlineButton(
          rateLimited: rateLimited,
          scope: 'search.next',
          failure: error,
          onRetry: () =>
              context.read<SearchResultBloc<T>>().add(const FetchNextPage()),
          label: rateLimited
              ? l10n.rateLimitedRetryLater
              : l10n.moreLoadFailedRetry,
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
            Icon(AppIcons.searchOff, size: 48, color: colorScheme.outline),
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

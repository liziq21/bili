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

  /// 宽屏下允许的最大列数。为 null 时不限制，列数完全由
  /// [maxCrossAxisExtent] 决定。
  ///
  /// 没有上限时，1280 宽会排出 7 列约 168px 的卡片，创作者与时长在这么
  /// 窄的卡片里会被丢弃；限制列数后每张卡片更宽，关键信息才放得下。
  final int? maxColumns,
}) extends StatefulWidget {
  @override
  State<SearchResult<T>> createState() => _SearchResultState<T>();
}

/// 每个 [SearchResult] 实例一份独立的冷却额度：不同 tab、不同搜索路由各自
/// 计数，不会把别处的拒绝当成自己的上一轮连击。
int _searchScopeSeq = 0;

class _SearchResultState<T>() extends State<SearchResult<T>> {
  final int _scopeId = _searchScopeSeq++;
  String get _firstPageScope => 'search.$_scopeId.first';
  String get _nextPageScope => 'search.$_scopeId.next';

  static const double _gridSpacing = 10.0;

  /// 把 [maxCrossAxisExtent] 放大到刚好只排得下 [SearchResult.maxColumns] 列。
  ///
  /// [SliverGridDelegateWithMaxCrossAxisExtent] 的列数是
  /// `ceil(width / (extent + spacing))`。要让宽度更富余时不再增加列，
  /// 就抬高 extent，使这个商刚好落在 [SearchResult.maxColumns] 上。
  double _effectiveMaxExtent(double availableWidth) {
    final maxColumns = widget.maxColumns;
    final extent = widget.maxCrossAxisExtent;
    if (maxColumns == null || maxColumns <= 0) return extent;

    final widthForColumns =
        (availableWidth - _gridSpacing * (maxColumns - 1)) / maxColumns;
    return widthForColumns > extent && widthForColumns.isFinite
        ? widthForColumns
        : extent;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SearchResultBloc<T>, SearchResultState<T>>(
      listenWhen: (previous, current) {
        final paging = current.pagingState;
        return !paging.isLoading &&
            paging.error == null &&
            paging.pages.isNotEmpty;
      },
      // 请求成功后清零：一次成功之后的首次拒绝应从头开始，而不是沿用上一轮。
      listener: (context, state) {
        resetRateLimitCooldown(_firstPageScope);
        resetRateLimitCooldown(_nextPageScope);
      },
      child:
          BlocSelector<
            SearchResultBloc<T>,
            SearchResultState<T>,
            ({PagingState<int, T> pagingState, bool refreshing})
          >(
            selector: (state) => (
              pagingState: state.pagingState,
              refreshing: state.pendingRefresh,
            ),
            builder: (context, data) {
              final state = data.pagingState;
              return LayoutBuilder(
                builder: (context, constraints) => CustomScrollView(
                  slivers: [
                    PagedSliverGrid<int, T>(
                      state: state,
                      fetchNextPage: () => context
                          .read<SearchResultBloc<T>>()
                          .add(const FetchNextPage()),
                      builderDelegate: PagedChildBuilderDelegate(
                        itemBuilder: widget.itemBuilder,
                        firstPageErrorIndicatorBuilder: (context, error) =>
                            _SearchErrorView<T>(
                              error: error,
                              scope: _firstPageScope,
                            ),
                        newPageErrorIndicatorBuilder: (context, error) =>
                            _NewPageErrorIndicator<T>(
                              error: error,
                              scope: _nextPageScope,
                              refreshing: data.refreshing,
                            ),
                        noItemsFoundIndicatorBuilder: (context) =>
                            const _EmptySearchIndicator(),
                      ),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: _effectiveMaxExtent(
                          constraints.maxWidth,
                        ),
                        mainAxisSpacing: _gridSpacing,
                        crossAxisSpacing: _gridSpacing,
                        // 💡 放弃固定 mainAxisExtent，改用自适应比例
                        childAspectRatio: widget.itemAspectRatio,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}

/// 首页搜索失败视图：图标 + 提示文案 + 明确重试按钮 + 触觉反馈 + 屏幕阅读器语义
///
/// 搜索的风控窗口里接口会返回 `code: 0` 但只有 `v_voucher`，服务包把它适配成
/// [RateLimitedFailure]；此时换成限流文案并让重试先冷静一段时间。
class const _SearchErrorView<T>({
  required final Object? error,
  required final String scope,
}) extends StatelessWidget {
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
            scope: scope,
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
class const _NewPageErrorIndicator<T>({
  required final Object? error,
  required final String scope,
  final bool refreshing = false,
}) extends StatelessWidget {
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
          scope: scope,
          failure: error,
          onRetry: () =>
              context.read<SearchResultBloc<T>>().add(const FetchNextPage()),
          label: rateLimited
              ? l10n.rateLimitedRetryLater
              : refreshing
              ? l10n.refreshFailedRetry
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

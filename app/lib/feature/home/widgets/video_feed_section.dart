import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/localization_file/app_localizations.dart';
import '../../../main.dart';
import '../../../ui/video_card.dart';
import '../bloc/home_bloc.dart';
import '../../../ui/common/rate_limit_retry.dart';
import '../home_config.dart';
import 'feed_status_view.dart';

/// 单个视频 Feed 区块（响应式网格 + 加载更多）
class const VideoFeedSection({
  super.key,
  required final FeedSectionState<VideoModel> section,
  required final HomeConfig homeConfig,
  required final ValueChanged<VideoModel> onVideoTap,
  required final VoidCallback onRetry,
  required final VoidCallback onLoadMore,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 筛选项已经标出当前是哪个 Feed，列表里再放一次区块标题是重复信息；
    // 翻页入口也按设计稿收到列表末尾居中，不挂在区块头上。
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: $styles.insets.sm,
            vertical: $styles.insets.xs,
          ),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              if (section.isFailure) {
                return SliverToBoxAdapter(
                  child: FeedStatusView.failure(
                    title: section.title,
                    onRetry: onRetry,
                    error: section.error,
                    retryScope: 'home.video.${section.id}',
                  ),
                );
              }
              if (section.isEmpty) {
                return SliverToBoxAdapter(
                  child: FeedStatusView.empty(title: section.title),
                );
              }

              final width = constraints.crossAxisExtent;
              final spacing = $styles.insets.sm;
              final columns = switch (MediaQuery.orientationOf(context)) {
                Orientation.portrait => homeConfig.gridColumnsPortrait,
                Orientation.landscape => homeConfig.gridColumnsLandscape,
              };
              final cardWidth = (width - spacing * (columns - 1)) / columns;

              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  mainAxisExtent: videoCardExtent(
                    context,
                    cardWidth,
                    variant: VideoCardVariant.feed,
                  ),
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (section.isInitialLoading) {
                      return const FeedSkeletonCard();
                    }
                    final video = section.items[index];
                    return VideoCard(
                      variant: VideoCardVariant.feed,
                      videoInfoBase: video,
                      onTap: () => onVideoTap(video),
                    );
                  },
                  childCount: section.isInitialLoading
                      ? columns
                      : section.items.length,
                ),
              );
            },
          ),
        ),
        // 只有真的列出了条目才谈得上「还有没有下一页」：骨架屏、失败与空列表
        // 之下挂一条「没有更多了」是在陈述一个并不存在的加载结果。
        if (!section.isInitialLoading && !section.isFailure && !section.isEmpty)
          SliverToBoxAdapter(
            child: _FeedFooter(section: section, onLoadMore: onLoadMore),
          ),
      ],
    );
  }
}

/// Feed 列表末尾的同步状态提示
///
/// 翻页入口与「已到底」提示合并成一处居中文案：独立按钮会占掉一整行高度，
/// 而这两条信息都只在列表末尾出现一次。
class const _FeedFooter({
  required final FeedSectionState<VideoModel> section,
  required final VoidCallback onLoadMore,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (section.isLoadingMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: $styles.insets.md),
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    final label = section.hasMore
        ? (l10n?.continueLoading ?? 'Load more')
        : (l10n?.noMoreItems ?? 'No more items');
    return Padding(
      padding: EdgeInsets.symmetric(vertical: $styles.insets.md),
      child: Center(
        child: section.hasMore
            ? _loadMore(context, label)
            : Text(
                label,
                style: $styles.text.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }

  /// 翻页入口
  ///
  /// 上一页被限流时，列表还在（`isFailure` 为假），按钮却会立刻再发一次同样
  /// 被拒的请求；这里和首屏失败一样先冷静一段时间。
  Widget _loadMore(BuildContext context, String label) {
    if (!isRateLimited(section.error)) {
      return TextButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onLoadMore();
        },
        child: Text(label),
      );
    }
    return RetryCooldownInlineButton(
      rateLimited: true,
      failure: section.error,
      onRetry: onLoadMore,
      label: label,
      scope: 'home.video.${section.id}',
    );
  }
}

import 'package:data/data.dart';
import 'package:material_ui/material_ui.dart';

import '../../../main.dart';
import '../../../ui/common/utils/layout_breakpoints.dart';
import '../../../ui/video_card.dart';
import '../bloc/home_bloc.dart';
import 'feed_status_view.dart';

/// 单个视频 Feed 区块（标题 + 响应式网格 + 加载更多）
class const VideoFeedSection({
  super.key,
  required final FeedSectionState<VideoModel> section,
  required final String sourceName,
  required final ValueChanged<VideoModel> onVideoTap,
  required final VoidCallback onRetry,
  required final VoidCallback onLoadMore,
}) extends StatelessWidget {
  /// 视频卡片高度：封面 16:9 + 文字区块，随字体缩放而变化，避免固定宽高比溢出
  static double cardExtent(BuildContext context, double cardWidth) {
    final textScaler = MediaQuery.textScalerOf(context);
    final titleStyle = $styles.text.title2;
    final titleHeight =
        textScaler.scale(titleStyle.fontSize ?? 14) * 1.25 * 2; // 最多两行
    final subtitleHeight =
        textScaler.scale($styles.text.bodySmall.fontSize ?? 14) * 1.4;

    return cardWidth * 9 / 16 +
        titleHeight +
        subtitleHeight +
        $styles.insets.sm * 2 +
        $styles.insets.xxs;
  }

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
                  ),
                );
              }
              if (section.isEmpty) {
                return SliverToBoxAdapter(
                  child: FeedStatusView.empty(title: section.title),
                );
              }

              final width = constraints.crossAxisExtent;
              final columns = LayoutSize.fromWidth(width).feedColumnsFor(width);
              final spacing = $styles.insets.sm;
              final cardWidth = (width - spacing * (columns - 1)) / columns;

              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  mainAxisExtent: cardExtent(context, cardWidth),
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (section.isInitialLoading) {
                      return const FeedSkeletonCard();
                    }
                    final video = section.items[index];
                    return VideoCard(
                      variant: VideoCardVariant.feed,
                      sourceBadge: sourceName,
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
        SliverToBoxAdapter(
          child: _FeedFooter(
            section: section,
            onLoadMore: onLoadMore,
            sourceName: sourceName,
          ),
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
  required final String sourceName,
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

    final label = section.hasMore ? '继续加载' : '没有更多了';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: $styles.insets.md),
      child: Center(
        child: section.hasMore
            ? TextButton(onPressed: onLoadMore, child: Text(label))
            : Text(
                label,
                style: $styles.text.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}

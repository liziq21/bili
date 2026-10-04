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
  ///
  /// 文字高度取 [VideoCard._buildFeedCard] 的真实渲染值，而非设计令牌的
  /// 默认值——两处都被 `copyWith` 覆写过：标题 `title2.copyWith(height: 1.25)`
  /// 覆盖了 title2 原有的 16.38/14≈1.17 行高，副标题
  /// `bodySmall.copyWith(fontSize: 12)` 覆盖了字号。字号仍从令牌读取：
  /// [$styles] 按屏幕尺寸整体缩放（宽屏 1.1 / 超宽 1.2），写死 14 会漏掉这一层。
  static double cardExtent(BuildContext context, double cardWidth) {
    final textScaler = MediaQuery.textScalerOf(context);
    // 标题：两行，行高 1.25 由 video_card.dart 的 copyWith 显式指定
    final titleHeight =
        textScaler.scale($styles.text.title2.fontSize ?? 14) * 1.25 * 2;
    // 副标题：字号被覆写为 12，行高沿用 bodySmall 的 heightPx / sizePx = 23/14
    final subtitleHeight =
        textScaler.scale(12) * ($styles.text.bodySmall.height ?? 1);

    return cardWidth * 9 / 16 +
        titleHeight +
        subtitleHeight +
        $styles.insets.sm * 2 +
        $styles.insets.xxs +
        2; // Material 内层 Padding(EdgeInsets.all(1)) 的上下各 1px
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

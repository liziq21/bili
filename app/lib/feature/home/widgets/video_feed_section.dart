import 'package:data/data.dart';
import 'package:material_ui/material_ui.dart';

import '../../../main.dart';
import '../../../ui/common/utils/layout_breakpoints.dart';
import '../../../ui/video_card.dart';
import '../bloc/home_bloc.dart';
import 'feed_section_header.dart';
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
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: FeedSectionHeader(
            title: section.title,
            subtitle: '$sourceName 推荐内容',
            icon: Icons.recommend_rounded,
          ),
        ),
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
              final columns = LayoutSize.fromWidth(width).feedColumns;
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
        if (section.hasMore || section.isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: $styles.insets.xs),
              child: Center(
                child: section.isLoadingMore
                    ? const CircularProgressIndicator()
                    : TextButton.icon(
                        onPressed: onLoadMore,
                        icon: const Icon(Icons.expand_more_rounded),
                        label: const Text('加载更多'),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

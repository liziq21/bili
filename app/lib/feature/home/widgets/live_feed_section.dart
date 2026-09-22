import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:material_ui/material_ui.dart';

import '../../../main.dart';
import '../../../ui/common/utils/layout_breakpoints.dart';
import '../bloc/home_bloc.dart';
import 'feed_section_header.dart';
import 'feed_status_view.dart';

/// 单个直播 Feed 区块（标题 + 横向卡片列表）
class LiveFeedSection extends StatelessWidget {
  const LiveFeedSection({
    super.key,
    required this.section,
    required this.sourceName,
    required this.onLiveTap,
    required this.onRetry,
  });

  final FeedSectionState<LiveRoomModel> section;
  final String sourceName;
  final ValueChanged<LiveRoomModel> onLiveTap;
  final VoidCallback onRetry;

  /// 直播卡片高度：封面 16:9 + 两行文字，随字体缩放而变化
  static double cardExtent(BuildContext context, double cardWidth) {
    final textScaler = MediaQuery.textScalerOf(context);
    final titleHeight =
        textScaler.scale($styles.text.bodySmallBold.fontSize ?? 14) * 1.5;
    final streamerHeight =
        textScaler.scale($styles.text.bodySmall.fontSize ?? 14) * 1.5;

    return cardWidth * 9 / 16 +
        titleHeight +
        streamerHeight +
        $styles.insets.xs * 2 +
        $styles.insets.xxs;
  }

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: FeedSectionHeader(
            title: section.title,
            subtitle: '$sourceName 正在直播',
            icon: Icons.sensors_rounded,
            iconColor: Theme.of(context).colorScheme.error,
          ),
        ),
        if (section.isFailure)
          SliverToBoxAdapter(
            child: FeedStatusView.failure(
              title: section.title,
              onRetry: onRetry,
            ),
          )
        else if (section.isEmpty)
          SliverToBoxAdapter(child: FeedStatusView.empty(title: section.title))
        else
          SliverLayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.crossAxisExtent;
              final cardWidth = LayoutSize.fromWidth(width)
                  .liveCardWidth(width);
              final itemCount = section.isInitialLoading
                  ? 3
                  : section.items.length;

              return SliverToBoxAdapter(
                child: SizedBox(
                  height: cardExtent(context, cardWidth),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: $styles.insets.sm,
                    ),
                    itemCount: itemCount,
                    separatorBuilder: (context, index) =>
                        SizedBox(width: $styles.insets.sm),
                    itemBuilder: (context, index) => SizedBox(
                      width: cardWidth,
                      child: section.isInitialLoading
                          ? const FeedSkeletonCard()
                          : _LiveRoomCard(
                              liveRoom: section.items[index],
                              onTap: () => onLiveTap(section.items[index]),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _LiveRoomCard extends StatelessWidget {
  const _LiveRoomCard({required this.liveRoom, required this.onTap});

  final LiveRoomModel liveRoom;
  final VoidCallback onTap;

  Widget _thumbnailPlaceholder(ColorScheme colorScheme) => Container(
    color: colorScheme.surfaceContainerHighest,
    child: Icon(Icons.live_tv, color: colorScheme.onSurfaceVariant),
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular($styles.corners.md),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: switch (liveRoom.thumbnailUrl) {
                    final String url when url.isNotEmpty => CachedNetworkImage(
                      imageUrl: url,
                      memCacheWidth: 320,
                      fit: BoxFit.cover,
                      errorBuilder: (context, url, error) =>
                          _thumbnailPlaceholder(colorScheme),
                    ),
                    _ => _thumbnailPlaceholder(colorScheme),
                  },
                ),
                if (liveRoom.isLive)
                  Positioned(
                    top: $styles.insets.xs,
                    left: $styles.insets.xs,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: $styles.insets.xs,
                        vertical: $styles.insets.xxs / 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular($styles.corners.sm),
                      ),
                      child: Text(
                        '直播中',
                        style: $styles.text.bodySmallBold.copyWith(
                          color: colorScheme.onError,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all($styles.insets.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        liveRoom.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: $styles.text.bodySmallBold.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        liveRoom.creatorProfileName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: $styles.text.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

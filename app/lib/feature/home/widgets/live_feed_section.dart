import 'dart:math' as math;

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/design.dart';
import '../../../l10n/localization_file/app_localizations.dart';
import '../../../main.dart';
import '../../../ui/common/horizontal_wheel_scroll.dart';
import '../../../ui/common/utils/layout_breakpoints.dart';
import '../bloc/home_bloc.dart';
import 'feed_status_view.dart';

/// 单个直播 Feed 区块（横向卡片列表）
class const LiveFeedSection({
  super.key,
  required final FeedSectionState<LiveRoomModel> section,
  required final ValueChanged<LiveRoomModel> onLiveTap,
  required final VoidCallback onRetry,
}) extends StatelessWidget {
  /// 直播卡片高度：封面 16:9 + 两行文字，随字体缩放而变化
  ///
  /// 文字高度必须取字体令牌的真实行高（`fontSize * height`）。早先按
  /// `fontSize * 1.5` 估算，而 `bodySmall` / `bodySmallBold` 的实际行高是
  /// 23/14 ≈ 1.643，每行少算 2px；两行文字靠 `Flexible` 挤进不足的高度里，
  /// 放大字号时下半截字形被裁掉。末尾 `ceilToDouble` 与视频卡片的
  /// `videoCardExtent` 一致，避免亚像素误差再次挤掉文字。
  static double cardExtent(BuildContext context, double cardWidth) {
    final textScaler = MediaQuery.textScalerOf(context);
    // 两行文字都是单行（maxLines: 1），行高由令牌的 height 比例决定。
    final titleLineHeight =
        ($styles.text.bodySmallBold.fontSize ?? 14) *
        ($styles.text.bodySmallBold.height ?? 1.643);
    final streamerLineHeight =
        ($styles.text.bodySmall.fontSize ?? 14) *
        ($styles.text.bodySmall.height ?? 1.643);

    return (cardWidth * 9 / 16 +
            textScaler.scale(titleLineHeight) +
            textScaler.scale(streamerLineHeight) +
            $styles.insets.xs * 2 +
            $styles.insets.xxs)
        .ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    // 筛选栏的 chip 已经标出当前 Feed，区块头再写一次同一个标题属于重复
    // 信息；视频区块同样不挂区块头，两种 Feed 保持一致。
    if (section.isFailure) {
      return SliverToBoxAdapter(
        child: FeedStatusView.failure(
          title: section.title,
          onRetry: onRetry,
          error: section.error,
          retryScope: 'home.live.${section.id}',
        ),
      );
    }
    if (section.isEmpty) {
      return SliverToBoxAdapter(
        child: FeedStatusView.empty(title: section.title),
      );
    }
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final horizontalPadding = $styles.insets.sm;
        // 卡片宽度按列表内层可用宽度算：横向 ListView 的 padding 在卡片之外，
        // 用外层宽度算会让最右一张卡超出可视区。列数也由这段可用宽度定，
        // 一屏只放完整的卡，剩下的余量均分进卡片，右侧不会露出半张。
        final metrics = LayoutSize.fromWidth(width).liveGridMetrics(
          math.max(0, width - horizontalPadding * 2),
          spacing: $styles.insets.sm,
        );
        final cardWidth = metrics.cardWidth;
        final itemCount = section.isInitialLoading ? 3 : section.items.length;

        return SliverToBoxAdapter(
          child: SizedBox(
            height: cardExtent(context, cardWidth),
            child: HorizontalWheelScroll(
              builder: (context, controller) => ListView.separated(
                controller: controller,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
          ),
        );
      },
    );
  }
}

class const _LiveRoomCard({
  required final LiveRoomModel liveRoom,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  Widget _thumbnailPlaceholder(ColorScheme colorScheme) => Container(
    color: colorScheme.surfaceContainerHighest,
    child: Icon(AppIcons.liveTv, color: colorScheme.onSurfaceVariant),
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final streamerName =
        liveRoom.creatorProfileName ?? (l10n?.unknownStreamer ?? 'Unknown');
    final semanticLabel = <String?>[
      liveRoom.title,
      l10n?.streamerLabel(streamerName),
    ].whereType<String>().join(l10n?.commaSeparator ?? ',');

    // ⚡ Bolt Optimization: Replace Card wrapper with a direct Material widget.
    // Eliminates redundant Card element node allocations and unifies surface background,
    // rounded corner clipping, and border stroke painting into a single canvas pass.
    // 不带投影：卡片下方露出的那截灰带正是投影被列表裁掉一半后的残留，
    // 边框已经足以把卡片和背景分开。
    return Material(
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular($styles.corners.md),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      // 封面是不透明的 Container，不裁剪时会盖住卡片的圆角：顶部两个圆角
      // 被画成直角，只有文字区露出的底部圆角还在。
      clipBehavior: Clip.antiAlias,
      child: Tooltip(
        message: liveRoom.title,
        child: Semantics(
          button: true,
          label: semanticLabel,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: switch (liveRoom.thumbnailUrl) {
                      final String url when url.isNotEmpty =>
                        CachedNetworkImage(
                          imageUrl: url,
                          memCacheWidth: 320,
                          fit: BoxFit.cover,
                          errorBuilder: (context, url, error) =>
                              _thumbnailPlaceholder(colorScheme),
                        ),
                      _ => _thumbnailPlaceholder(colorScheme),
                    },
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
          ),
        ),
      ),
    );
  }
}

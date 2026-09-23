import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../main.dart';
import '../bloc/home_bloc.dart';

/// 常驻在主页顶部的横向筛选栏
///
/// 使用 [SliverPersistentHeader] 固定，避免滚动后失去主导航入口。
class HomeFilterBar extends SliverPersistentHeaderDelegate {
  const HomeFilterBar({
    required this.filters,
    required this.activeFilterId,
    required this.onSelected,
    required this.height,
  });

  final List<HomeFilter> filters;
  final String activeFilterId;
  final ValueChanged<HomeFilter> onSelected;
  final double height;

  /// 筛选栏高度：chip 文字高度 + 上下内边距，随字体缩放而变化
  static double preferredHeight(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    return textScaler.scale($styles.text.bodySmall.fontSize ?? 14) * 1.4 +
        $styles.insets.sm +
        $styles.insets.xs * 2;
  }

  static IconData iconFor(HomeFilter filter) => switch (filter.rawId) {
    'all' => Icons.auto_awesome_rounded,
    'top100' => Icons.local_fire_department_rounded,
    'hot' || 'trending' => Icons.whatshot_rounded,
    'recommend' => Icons.recommend_rounded,
    'sub' => Icons.rss_feed_rounded,
    'bookmarks' => Icons.bookmark_border_rounded,
    'downloaded' => Icons.download_done_rounded,
    'history' => Icons.history_rounded,
    _ => switch (filter.kind) {
      HomeFilterKind.liveFeed => Icons.sensors_rounded,
      _ => Icons.video_library_rounded,
    },
  };

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: overlapsContent ? 2 : 0,
      child: SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: $styles.insets.sm,
            vertical: $styles.insets.xs,
          ),
          itemCount: filters.length,
          separatorBuilder: (context, index) =>
              SizedBox(width: $styles.insets.xs),
          itemBuilder: (context, index) {
            final filter = filters[index];
            final isSelected = filter.id == activeFilterId;

            return Center(
              child: FilterChip(
                selected: isSelected,
                showCheckmark: false,
                avatar: Icon(
                  iconFor(filter),
                  size: $styles.insets.sm,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
                label: Text(filter.label),
                labelStyle: $styles.text.bodySmall.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
                selectedColor: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerHighest,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular($styles.corners.lg),
                ),
                tooltip: '切换至${filter.label}',
                onSelected: (selected) {
                  if (selected) {
                    HapticFeedback.selectionClick();
                  }
                  onSelected(filter);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(HomeFilterBar oldDelegate) =>
      !listEquals(oldDelegate.filters, filters) ||
      oldDelegate.activeFilterId != activeFilterId ||
      oldDelegate.height != height;
}

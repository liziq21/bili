import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../main.dart';
import '../../../ui/common/horizontal_wheel_scroll.dart';
import '../bloc/home_bloc.dart';

/// 常驻在主页顶部的横向筛选栏
///
/// 使用 [SliverPersistentHeader] 固定，避免滚动后失去主导航入口。
class const HomeFilterBar({
  required final List<HomeFilter> filters,
  required final String activeFilterId,
  required final ValueChanged<HomeFilter> onSelected,
  required final double height,
}) extends SliverPersistentHeaderDelegate {
  /// 筛选栏高度：chip 文字高度 + 上下内边距，随字体缩放而变化
  static double preferredHeight(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    return textScaler.scale($styles.text.bodySmall.fontSize ?? 14) * 1.4 +
        $styles.insets.sm +
        $styles.insets.xs * 2;
  }

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
        child: HorizontalWheelScroll(
          builder: (context, controller) => ListView.separated(
            controller: controller,
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
                  tooltip: filter.label,
                  label: Text(filter.label, textAlign: TextAlign.center),
                  labelStyle: $styles.text.bodySmall.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
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
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    onSelected(filter);
                  },
                ),
              );
            },
          ),
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

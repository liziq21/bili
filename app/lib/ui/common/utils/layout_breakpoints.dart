import 'package:flutter/widgets.dart';

/// 应用统一的响应式宽度档位
enum LayoutSize() {
  /// 手机竖屏等紧凑宽度（< 600）
  compact,

  /// 大屏手机横屏 / 小平板（600 ~ 900）
  medium,

  /// 平板横屏 / 桌面（>= 900）
  expanded;

  /// 根据可用宽度 [width] 推断当前档位
  static LayoutSize fromWidth(double width) {
    if (width >= 900) return LayoutSize.expanded;
    if (width >= 600) return LayoutSize.medium;
    return LayoutSize.compact;
  }

  /// 根据 [context] 的屏幕宽度推断当前档位
  static LayoutSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  /// 视频网格在该档位下的列数
  int get feedColumns => switch (this) {
    LayoutSize.compact => 1,
    LayoutSize.medium => 2,
    LayoutSize.expanded => 3,
  };

  /// 该档位下单张视频卡片的目标宽度（逻辑像素）
  double get feedTargetCardWidth => switch (this) {
    LayoutSize.compact => 320,
    LayoutSize.medium => 300,
    LayoutSize.expanded => 240,
  };

  /// 按实际可用宽度 [width] 解析视频网格列数
  ///
  /// [feedColumns] 只是各档位的下限：当可用宽度超过该档位的起点之后，按目标
  /// 卡片宽度继续增加列数。列间距也要计入预算，否则新增一列后卡片会立刻小于
  /// [feedTargetCardWidth]。
  int feedColumnsFor(double width, {double spacing = 0}) {
    final int byTargetWidth =
        ((width + spacing) / (feedTargetCardWidth + spacing)).floor();
    return byTargetWidth > feedColumns ? byTargetWidth : feedColumns;
  }

  /// 直播横向列表在该档位下的目标卡片宽度（相对可用宽度 [width] 计算）
  double liveCardWidth(double width) => switch (this) {
    LayoutSize.compact => (width * 0.58).clamp(200.0, 280.0),
    LayoutSize.medium => (width * 0.38).clamp(240.0, 320.0),
    // 桌面端按"一屏能看到几张卡"来定宽，而不是按宽度比例，否则宽屏上
    // 单张卡片会无限变大。
    LayoutSize.expanded => (width / 4.2).clamp(240.0, 320.0),
  };

  /// 直播列表的横向排布：按目标卡宽定出整数张卡，再把余量均分给卡片。
  ///
  /// 只按目标宽度切卡会让最右一张超出可用宽度（一屏 4 张时溢出十几像素），
  /// 视口窄于目标宽度时更是整张卡落在窗口外。这里先算「能完整放下几张」，
  /// 再让这些卡精确铺满可用宽度，两侧留白由调用方的 padding 决定，因此
  /// 四边留白一致，且任何宽度下都不会裁到卡片。
  ({int columns, double cardWidth}) liveGridMetrics(
    double availableWidth, {
    double spacing = 0,
  }) {
    final width = availableWidth < 0 ? 0.0 : availableWidth;
    final target = liveCardWidth(width);
    final fitting = ((width + spacing) / (target + spacing)).floor();
    final columns = fitting < 1 ? 1 : fitting;
    final free = width - spacing * (columns - 1);
    return (columns: columns, cardWidth: free <= 0 ? 0.0 : free / columns);
  }
}

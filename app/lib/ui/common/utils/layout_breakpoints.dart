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

  /// 直播横向列表在该档位下的卡片宽度（相对可用宽度 [width] 计算）
  double liveCardWidth(double width) => switch (this) {
    LayoutSize.compact => (width * 0.58).clamp(200.0, 280.0),
    LayoutSize.medium => (width * 0.38).clamp(240.0, 320.0),
    LayoutSize.expanded => (width * 0.28).clamp(260.0, 360.0),
  };
}

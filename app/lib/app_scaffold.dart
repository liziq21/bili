import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sized_context/sized_context.dart';

import 'main.dart';
import 'design/design.dart';
import 'ui/common/app_scroll_behavior.dart';

class const AppScaffold({super.key, required final Widget child})
    extends StatelessWidget {
  static AppStyle get style => _style;
  static AppStyle _style = AppStyle();

  @override
  Widget build(BuildContext context) {
    // Listen to the device size, and update AppStyle when it changes
    final mq = MediaQuery.of(context);
    //appLogic.handleAppSizeChanged(mq.size);
    // Set default timing for animations in the app
    Animate.defaultDuration = _style.times.fast;
    // Create a style object that will be passed down the widget tree
    _style = AppStyle(
      screenSize: context.sizePx,
      disableAnimations: mq.disableAnimations,
      // Read the real theme brightness so `$styles.colors.*` can pick light or
      // dark values. Previously `AppColors.isDark` was hardcoded to false,
      // which pinned every surface and text colour to the light palette and
      // left the whole app light-only.
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
    return KeyedSubtree(
      key: ValueKey($styles.scale),
      child: Theme(
        data: appThemeData($styles.colors),
        // 品牌色板作为 Material 组件的默认配色（P3 接线）；
        // 不接线时 Material 走 stock ThemeData.light()，$styles.colors.*
        // 的取值就只是装饰、不影响组件渲染（R4 双色板问题的实质）。
        child: /* 外层 Theme(data:) 提供 AppColors 取值，DefaultTextStyle
               提供 Material 之外的 widget（Hero 飞行等）的字样。 */
            DefaultTextStyle(
          style: $styles.text.body,
          // Use a custom scroll behavior across entire app
          child: ScrollConfiguration(behavior: AppScrollBehavior(), child: child),
        ),
      ),
    );
  }
}

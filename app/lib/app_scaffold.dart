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
      // 动态色开启时上层 Theme 的色板是系统色板（R5 要求动态色优先），
      // 自研 token 必须跟着换，否则 TabBar.indicatorColor 这类取
      // accentFill 的地方会与 Material 默认 primary 分叉。关闭动态色时
      // 该色板就是品牌色板，AppStyle 内部原样返回，默认路径不变。
      scheme: Theme.of(context).colorScheme,
    );
    return KeyedSubtree(
      key: ValueKey($styles.scale),
      // 这里不建 Theme：品牌色板已由 ThemeWrapper 交给 MaterialApp.router
      // 的 theme/darkTheme（app.dart:47-59），本组件在路由子树内，
      // Theme.of(context) 拿到的就是它。再建一层 Theme(data:) 会用
      // $styles.colors 重算 ColorScheme 覆盖掉上层——动态色开启时
      // DynamicColorBuilder 换上的动态色板就是这样被吃掉的（R5 要求动态
      // 色优先于品牌色）。
      //
      // DefaultTextStyle 仍要留：它给 Hero 飞行目标等 Material 之外的
      // widget 提供字样。
      child: DefaultTextStyle(
        style: $styles.text.body,
        // Use a custom scroll behavior across entire app
        child: ScrollConfiguration(behavior: AppScrollBehavior(), child: child),
      ),
    );
  }
}

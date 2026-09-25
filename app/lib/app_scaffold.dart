import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sized_context/sized_context.dart';

import 'main.dart';
import 'styles/styles.dart';
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
      highContrast: mq.highContrast,
      // Read the real theme brightness so `$styles.colors.*` can pick light or
      // dark values. Previously `AppColors.isDark` was hardcoded to false,
      // which pinned every surface and text colour to the light palette and
      // left the whole app light-only.
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
    return KeyedSubtree(
      key: ValueKey($styles.scale),
      child: /*Theme(
        data: $styles.colors.toThemeData(),
        // Provide a default texts style to allow Hero's to render text properly
        child: */ DefaultTextStyle(
        style: $styles.text.body,
        // Use a custom scroll behavior across entire app
        child: ScrollConfiguration(behavior: AppScrollBehavior(), child: child),
      ),
      //),
    );
  }
}

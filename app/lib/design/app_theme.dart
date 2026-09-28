import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// 由 [AppColors] 构造 `ThemeData`。
///
/// **本文件在 P2 阶段不接线**：`App`/`ThemeWrapper` 仍走 `ThemeData.light()`
/// / `ThemeData.dark()`，Material 组件因此拿到的还是默认配色。接线属于 P3，
/// 目的是让「改变像素」只发生在那一个提交里。
///
/// 接线时必须复用 [AppColors] 背后的同一个 `ColorScheme`，否则会出现两套
/// 独立色板（R4 想消除的正是这个）。
ThemeData appThemeData(AppColors colors) {
  final scheme = colors.scheme;
  final textTheme = switch (scheme.brightness) {
    Brightness.light => ThemeData.light().textTheme,
    Brightness.dark => ThemeData.dark().textTheme,
  };

  return ThemeData.from(textTheme: textTheme, colorScheme: scheme).copyWith(
    textSelectionTheme: TextSelectionThemeData(cursorColor: colors.accentFill),
    highlightColor: colors.accentFill,
  );
}

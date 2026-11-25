import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// 按压 / 水波纹状态层的透明度。
///
/// 状态层是**叠加**在表面之上的半透明色，不能替换表面：不透明的
/// [AppColors.accentFill] 会把整张卡片刷成实心强调色，压在卡片副标题
/// （`onSurfaceVariant`）上只剩 1.25:1（亮）/ 1.28:1（暗），文字无法辨认。
/// 8% 下表面仍然透出，卡片上的 `onSurface` / `onSurfaceVariant` 都保持
/// WCAG AA（≥ 4.5:1），实测值见 `test/design/contrast_test.dart`。
const double _stateLayerOpacity = 0.08;

/// 由 [AppColors] 构造 `ThemeData`。
///
/// 接线时必须复用 [AppColors] 背后的同一个 `ColorScheme`，否则会出现两套
/// 独立色板（R4 想消除的正是这种）。
ThemeData appThemeData(AppColors colors) {
  final scheme = colors.scheme;
  final textTheme = switch (scheme.brightness) {
    Brightness.light => ThemeData.light().textTheme,
    Brightness.dark => ThemeData.dark().textTheme,
  };
  final stateLayer = colors.accentFill.withValues(alpha: _stateLayerOpacity);

  return ThemeData.from(textTheme: textTheme, colorScheme: scheme).copyWith(
    textSelectionTheme: TextSelectionThemeData(cursorColor: colors.accentFill),
    highlightColor: stateLayer,
    splashColor: stateLayer,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        // iOS 不在此表：material_ui 的 PageTransitionsTheme 对缺失键回落到
        // CupertinoPageTransitionsBuilder（page_transitions_theme.dart 的
        // `builders[platform] ?? switch (platform)`），该路径才带边缘滑动返回手势。
        // 显式写 Zoom 会去掉手势；显式写 CupertinoPageTransitionsBuilder 则需
        // import package:cupertino_ui（bili 未直接依赖，违反 AGENTS.md 第 58 行）。
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      },
    ),
  );
}

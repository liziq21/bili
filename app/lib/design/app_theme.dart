import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// 按压 / 水波纹状态层的透明度。
///
/// 状态层叠加在表面之上、不替换表面（R2.5）：不透明的 [AppColors.accentFill]
/// 会把整张卡片刷成实心强调色，卡片副标题（`onSurfaceVariant`）随之失去对比度。
/// 高亮与波纹会重叠，取值以叠加后的结果为准，见
/// `test/design/contrast_test.dart`。
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
    // Material 的默认 Tooltip 用固定灰/白（material_ui 的 tooltip.dart 按亮度
    // 取 grey[700] / white），不读品牌色板；长按图标、底栏目的地时弹出的说明
    // 文本会明显与主题脱节。说明文本是浮在页面之上的恒深承载面，取
    // scrim / onScrim 这对角色（R2）。
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: colors.scrim,
        // 与 Material Tooltip 默认圆角一致；该组件内边距/圆角是固定值，不随
        // 布局尺度缩放（R2.4）。
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: textTheme.bodyMedium?.copyWith(color: colors.onScrim),
    ),
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

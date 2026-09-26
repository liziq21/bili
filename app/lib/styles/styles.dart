// ignore_for_file: library_private_types_in_public_api

import 'package:material_ui/material_ui.dart';

import 'colors.dart';

export 'colors.dart';

@immutable
class AppStyle({
  Size? screenSize,
  final bool disableAnimations = false,
  final bool isDark = false,
}) {
  this {
    if (screenSize == null) {
      scale = 1;
      return;
    }
    final shortestSide = screenSize.shortestSide;
    const tabletXl = 1000;
    const tabletLg = 800;
    if (shortestSide > tabletXl) {
      scale = 1.2;
    } else if (shortestSide > tabletLg) {
      scale = 1.1;
    } else {
      scale = 1;
    }
  }

  late final double scale;

  /// The current theme colors for the app
  late final AppColors colors = AppColors(isDark: isDark);

  /// Rounded edge corner radii
  late final _Corners corners = const _Corners();

  /// Padding and margin values
  late final _Insets insets = _Insets(scale);

  /// Text styles
  late final _Text text = _Text(scale);

  /// Animation Durations
  late final _Times times = _Times(disableAnimations);
}

class _Text(final double _scale) {
  /// 字体族已按 R6 全部删除。仓库从未 bundle 任何字体文件（0 个 `.ttf`/`.otf`），
  /// 从前声明的 6 个族——Tenor / B612Mono / Cinzel / MaShanZheng / Yeseva /
  /// Raleway——在每个平台都静默回落到系统字体。半死的配置比没有配置更糟：
  /// 读代码的人以为换了字体，实际什么都没变。
  ///
  /// 字体族现在由 Material `textTheme` 决定，但**机制不在 `AppScaffold`**：
  /// `AppScaffold` 用的是 `DefaultTextStyle(style:)`，那是**替换**而非合并，
  /// 它自己不带 `fontFamily`。真正把主题字体族送到普通 `Text` 的是
  /// `Material` 内部那层 `AnimatedDefaultTextStyle(theme.textTheme.bodyMedium)`
  /// （`material.dart:476`）。因为 `Material` 位于 `AppScaffold` 之下、对
  /// `Text` 更近，`AppScaffold` 这层只对 `Material` 之外的 widget 生效
  /// （Hero 飞行等）。
  ///
  /// 实测确认：主题声明 `fontFamily` 时，`Scaffold` 内的普通 `Text` 拿到的
  /// 就是主题的族，与 `AppScaffold` 这层无关。
  ///
  /// [baseKern] 保留了原先只挂在 Raleway 上的 `kern` 特性。**它不是可以顺手
  /// 一起删的死配置**：实测（用 SDK 自带 Roboto 经 `FontLoader` 装载后逐字形
  /// 比对 caret 位置）开启 `kern` 会让 23 个字形里的 22 个发生位移，
  /// fontSize 40 时最大差约 15px。而 h3 / title2 原先走 Tenor、本就没有这个
  /// 特性，所以这里保留两个基底，而不是统一成一个——统一任一方向都会改变
  /// 真实设备的渲染结果。
  static const TextStyle base = TextStyle();

  static const TextStyle baseKern = TextStyle(
    fontFeatures: [FontFeature.enable('kern')],
  );

  late final TextStyle h3 = _createFont(
    base,
    sizePx: 24,
    heightPx: 36,
    weight: FontWeight.w600,
  );

  late final TextStyle title2 = _createFont(base, sizePx: 14, heightPx: 16.38);

  late final TextStyle body = _createFont(baseKern, sizePx: 16, heightPx: 26);
  late final TextStyle bodyBold = _createFont(
    baseKern,
    sizePx: 16,
    heightPx: 26,
    weight: FontWeight.w600,
  );
  late final TextStyle bodySmall = _createFont(
    baseKern,
    sizePx: 14,
    heightPx: 23,
  );
  late final TextStyle bodySmallBold = _createFont(
    baseKern,
    sizePx: 14,
    heightPx: 23,
    weight: FontWeight.w600,
  );

  late final TextStyle caption = _createFont(
    baseKern,
    sizePx: 14,
    heightPx: 20,
    weight: FontWeight.w500,
  ).copyWith(fontStyle: FontStyle.italic);

  late final TextStyle btn = _createFont(
    baseKern,
    sizePx: 14,
    weight: FontWeight.w500,
    spacingPc: 2,
    heightPx: 14,
  );

  TextStyle _createFont(
    TextStyle style, {
    required double sizePx,
    double? heightPx,
    double? spacingPc,
    FontWeight? weight,
  }) {
    sizePx *= _scale;
    if (heightPx != null) {
      heightPx *= _scale;
    }
    return style.copyWith(
      fontSize: sizePx,
      height: heightPx != null ? (heightPx / sizePx) : style.height,
      letterSpacing: spacingPc != null
          ? sizePx * spacingPc * 0.01
          : style.letterSpacing,
      fontWeight: weight,
    );
  }
}

@immutable
class const _Times(final bool disableAnimations) {
  final Duration fast = disableAnimations
      ? const Duration(milliseconds: 1)
      : const Duration(milliseconds: 300);
  final Duration med = disableAnimations
      ? const Duration(milliseconds: 1)
      : const Duration(milliseconds: 600);
  final Duration slow = disableAnimations
      ? const Duration(milliseconds: 1)
      : const Duration(milliseconds: 900);
  final Duration extraSlow = disableAnimations
      ? const Duration(milliseconds: 1)
      : const Duration(milliseconds: 1300);
  final Duration pageTransition = disableAnimations
      ? const Duration(milliseconds: 1)
      : const Duration(milliseconds: 200);
}

@immutable
class const _Corners() {
  final double sm = 4;
  final double md = 8;
  final double lg = 32;
}

@immutable
class const _Insets(double scale) {
  this
    : xxs = 4 * scale,
      xs = 8 * scale,
      sm = 16 * scale,
      md = 24 * scale,
      lg = 32 * scale,
      xl = 48 * scale,
      xxl = 56 * scale,
      offset = 80 * scale;

  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double offset;
}

// ignore_for_file: library_private_types_in_public_api

import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'brand_palette.dart';

/// 排版尺度、圆角、间距、动效时长。与颜色无关的部分。
///
/// 颜色一律走 [colors]（R2/R4），本类不持有色值。
@immutable
class AppStyle({
  Size? screenSize,
  final bool disableAnimations = false,
  final bool isDark = false,
  final ColorScheme? scheme,
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

  /// 品牌色板（R1 的唯一来源）。[isDark] 由 `AppScaffold` 从真实的
  /// `Theme.of(context).brightness` 传入（R3：亮度只有这一个来源）。
  ///
  /// [scheme] 是上层 `Theme` 的实际色板：动态色开启时那是系统色板，此时
  /// 按 [BrandPalette.fromScheme] 跟随，让自研 token 与 Material 默认色
  /// 同源（R5）；为 null（默认）时按亮度取品牌色板。关闭动态色时上层色板
  /// 本身即品牌色板，`fromScheme` 原样返回，两条路径等价。
  late final BrandPalette palette = BrandPalette.fromScheme(
    scheme ?? _brand.scheme,
    base: _brand,
  );

  BrandPalette get _brand =>
      BrandPalette.of(isDark ? Brightness.dark : Brightness.light);

  /// The current theme colors for the app
  late final AppColors colors = AppColors(palette);

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
  /// 字体族声明已按 R6 全部移除。
  ///
  /// 移除依据：仓库未声明任何字体资源（`pubspec.yaml` 无 `fonts:` 块，仓库内
  /// 无 `.ttf`/`.otf` 文件）。原先声明的 Tenor / B612Mono / Cinzel /
  /// MaShanZheng / Yeseva / Raleway 六个族在所有平台均无法解析，实际生效的
  /// 均为平台默认字体。保留无法解析的族声明只会使代码与实际渲染不一致。
  ///
  /// 移除后的生效路径：由 `Material` 创建的
  /// `AnimatedDefaultTextStyle(style: theme.textTheme.bodyMedium)` 提供
  /// （`material.dart:476`）。`AppScaffold` 的
  /// `DefaultTextStyle(style: $styles.text.body)` 是整体替换上层样式、不与
  /// 之合并，其自身不含 `fontFamily`；且 `Material` 位于 `AppScaffold` 之下、
  /// 对 `Text` 更近，故该层仅对 `Material` 之外的 widget 生效（Hero 飞行等）。
  /// 实测：主题声明 `fontFamily` 时，`Scaffold` 内未显式指定 `style` 的
  /// `Text` 取到的即主题声明的族。
  ///
  /// [baseKern] 保留 `kern` 特性。依据：在 `flutter_test` 中以 `FontLoader`
  /// 装载 SDK 自带 Roboto、fontSize 40 的条件下逐字形比对 caret 位置，开启
  /// `kern` 使 23 个字形中的 22 个发生位移，最大位移约 15px。`h3` / `title2`
  /// 原先走 Tenor、不带该特性，故保留 [base] 与 [baseKern] 两个基底而不合并
  /// 为一个：任一方向的合并都会改变真实设备上的渲染结果。
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

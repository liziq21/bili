import 'package:material_ui/material_ui.dart';

import 'brand_palette.dart';

/// 按角色命名的颜色访问器（R2）——不含任何外观名（black / white / offWhite /
/// greyMedium / accent1 …）。
///
/// 全部取值来自 [BrandPalette]：Material 角色读 `ColorScheme`，三个
/// `ColorScheme` 无法表达的角色（[scrim] / [onScrim] / [onSurfaceStrong]）
/// 由色板直接携带。**本类不持有任何颜色字面量**（R4）。
@immutable
class const AppColors(final BrandPalette _palette) {
  /// 本组颜色背后的 `ColorScheme`。接线 ThemeData 时必须复用它，否则会
  /// 出现两套独立色板（R4）。
  ColorScheme get scheme => _palette.scheme;

  /// 构造后即可跟随最终生效的 [ColorScheme]（R4）——不需要在两处各维护一份
  /// 色值。
  Color get surface => _palette.scheme.surface;

  /// 面板底：与 [surface] 同源，比页面底略高一层。
  Color get surfaceContainerHighest => _palette.scheme.surfaceContainerHighest;

  /// 正文文字。
  Color get onSurface => _palette.scheme.onSurface;

  /// 弱化文字（时间戳、标签）。
  Color get onSurfaceVariant => _palette.scheme.onSurfaceVariant;

  /// 最强前景（浅底上的近黑文字）。见 [BrandPalette.onSurfaceStrong]。
  Color get onSurfaceStrong => _palette.onSurfaceStrong;

  /// 恒深承载面（视频占位底、日志面板、渐变遮罩、时长标签底）。
  Color get scrim => _palette.scrim;

  /// 压在 [scrim] 之上的浅色前景。
  Color get onScrim => _palette.onScrim;

  /// 强调色，容器底与图形用。
  Color get accentFill => _palette.scheme.primary;

  /// 强调色，直接压在 [surface] 上的文字/图标。
  ///
  /// 与 [accentFill] 当前取值相同。按 R2.1 二者最终须分档：文本用
  /// 4.5:1 的 [accentText]，非文本指示器用 3:1 的 [accentFill]。分档取值
  /// 属于改像素，在 P3 落地——P2 承诺零像素变化。
  Color get accentText => _palette.scheme.primary;

  /// 压在 [accentFill] 之上的前景。
  Color get onAccentFill => _palette.scheme.onPrimary;

  /// 次级强调。
  Color get secondary => _palette.scheme.secondary;

  /// 三级强调。
  Color get tertiary => _palette.scheme.tertiary;

  /// 分隔线与弱图形。
  Color get outline => _palette.scheme.outline;
}

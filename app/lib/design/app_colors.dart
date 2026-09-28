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
  /// 与 [accentFill] 按 R2.1 分档：文字 4.5:1，图形 3:1。亮色下二者取值
  /// 不同——`accentFill` 只有 4.00:1，够图形不够文字，故 [BrandPalette]
  /// 另带一个 `accentText`（5.12:1）。暗色下 accent 本身已有 8.68:1，
  /// 两档同值。
  Color get accentText => _palette.accentText;

  /// 压在 [accentFill] 之上的前景。
  Color get onAccentFill => _palette.scheme.onPrimary;

  /// 次级强调。
  Color get secondary => _palette.scheme.secondary;

  /// 三级强调。
  Color get tertiary => _palette.scheme.tertiary;

  /// 分隔线与弱图形。
  Color get outline => _palette.scheme.outline;
}

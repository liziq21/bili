import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

import 'app_colors.dart';
import 'app_theme.dart';
import 'brand_palette.dart';

/// Platform dynamic color schemes resolved once, before the first frame.
///
/// Both fields are null when the platform does not expose a dynamic palette;
/// callers then fall back to [BrandPalette].
@immutable
class const DynamicColorSchemes({
  final ColorScheme? light,
  final ColorScheme? dark,
}) with Equatable {
  @override
  List<Object?> get props => [light, dark];
}

/// How long startup waits for the platform palette before falling back.
///
/// The wait bounds the first-frame delay on platforms that never answer. A
/// timeout keeps the brand palette for the whole session, which is the stable
/// outcome the theme contract asks for.
const Duration _dynamicColorTimeout = Duration(milliseconds: 500);

/// Resolves the platform dynamic palette once so the first frame already uses
/// the final theme.
///
/// `DynamicColorBuilder` requests the palette from `initState` and rebuilds
/// when it arrives. That makes the first frame always render the brand
/// fallback, then visibly repaints the whole app with the system palette once
/// the platform answers (typically after the first input event on GTK). Reading
/// the same plugin API before `runApp` removes that mid-session switch.
Future<DynamicColorSchemes> resolveDynamicColorSchemes() async {
  try {
    final palette = await DynamicColorPlugin.getCorePalette().timeout(
      _dynamicColorTimeout,
    );
    if (palette != null) {
      return DynamicColorSchemes(
        light: palette.toColorScheme(),
        dark: palette.toColorScheme(brightness: Brightness.dark),
      );
    }
  } on Exception {
    // Fall through to the accent-color path used by desktop platforms.
  }

  try {
    final accent = await DynamicColorPlugin.getAccentColor().timeout(
      _dynamicColorTimeout,
    );
    if (accent != null) {
      return DynamicColorSchemes(
        light: ColorScheme.fromSeed(seedColor: accent),
        dark: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
        ),
      );
    }
  } on Exception {
    // No dynamic color on this platform.
  }

  return const DynamicColorSchemes();
}

typedef ThemeBuilder = Widget Function(
  ThemeData theme,
  ThemeData darkTheme,
  ThemeMode themeModel,
);

class const ThemeWrapper({
  super.key,
  required final bool useDynamicColor,
  required final ThemeConfig themeConfig,
  required final ThemeBuilder builder,

  /// Palette resolved before the first frame by [resolveDynamicColorSchemes].
  ///
  /// When provided, it is used as-is for the whole session: the widget never
  /// subscribes to later platform updates, so the theme cannot change under the
  /// user. When null the widget falls back to [DynamicColorBuilder].
  final DynamicColorSchemes? dynamicSchemes,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeMode themeMode = switch (themeConfig) {
      .followSystem => .system,
      .light => .light,
      .dark => .dark,
    };

    // P3 接线：主题数据来自 BrandPalette（R1 唯一来源），不再走
    // stock ThemeData.light()/dark()，使 Material 组件拿到的是品牌色板
    // 而非默认配色（R4 想消除的双色板问题）。
    final light = appThemeData(AppColors(BrandPalette.of(Brightness.light)));
    final dark = appThemeData(AppColors(BrandPalette.of(Brightness.dark)));

    if (useDynamicColor) {
      final resolved = dynamicSchemes;
      if (resolved != null) {
        // R5 动态色优先，但只在启动前解析完成时生效：会话内不再切换。
        return builder(
          _themed(Brightness.light, resolved.light),
          _themed(Brightness.dark, resolved.dark),
          themeMode,
        );
      }

      return DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          // R5 动态色优先：系统提供 DynamicColor 时压过品牌色。
          final theme = lightDynamic != null
              ? appThemeData(
                  AppColors(
                    BrandPalette.fromScheme(
                      lightDynamic,
                      base: BrandPalette.of(Brightness.light),
                    ),
                  ),
                )
              : light;
          final darkTheme = darkDynamic != null
              ? appThemeData(
                  AppColors(
                    BrandPalette.fromScheme(
                      darkDynamic,
                      base: BrandPalette.of(Brightness.dark),
                    ),
                  ),
                )
              : dark;
          return builder(theme, darkTheme, themeMode);
        },
      );
    }

    return builder(light, dark, themeMode);
  }

  ThemeData _themed(Brightness brightness, ColorScheme? scheme) {
    final base = BrandPalette.of(brightness);
    if (scheme == null) return appThemeData(AppColors(base));
    return appThemeData(AppColors(BrandPalette.fromScheme(scheme, base: base)));
  }
}

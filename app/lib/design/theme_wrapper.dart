import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

import 'app_colors.dart';
import 'app_theme.dart';
import 'brand_palette.dart';

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
}

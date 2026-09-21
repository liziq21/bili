import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:model/model.dart';

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
  static final baseLight = ThemeData.light();
  static final baseDark = ThemeData.dark();

  @override
  Widget build(BuildContext context) {
    final ThemeMode themeMode = switch (themeConfig) {
      .followSystem => .system,
      .light => .light,
      .dark => .dark,
    };

    if (useDynamicColor) {
      return _buildWithDynamicColor(themeMode: themeMode);
    }

    return builder(baseLight, baseDark, themeMode);
  }

  Widget _buildWithDynamicColor({required ThemeMode themeMode}) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final theme = lightDynamic != null
            ? baseLight.copyWith(colorScheme: lightDynamic as ColorScheme?)
            : baseLight;
        final darkTheme = darkDynamic != null
            ? baseDark.copyWith(colorScheme: darkDynamic as ColorScheme?)
            : baseDark;

        return builder(theme, darkTheme, themeMode);
      },
    );
  }
}

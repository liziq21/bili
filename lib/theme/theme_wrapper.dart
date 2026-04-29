import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import '../data/model/uesr_data.dart';

typedef ThemeBuilder = Widget Function(ThemeModel theme, ThemeModel darkTheme, bool useDynamicColor);

class ThemeWrapper extends StatelessWidget {
  const ThemeWrapper({
    super.key,
    required this.useDynamicColor,
    required this.themeConfig,
    required this.builder,
  });

  final Stream<bool> useDynamicColor;
  final Stream<ThemeConfig> themeConfig;
  final ThemeBuilder builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: useDynamicColor,
      builder: (_, snapshot) {
        ThemeData theme = const .light();
        ThemeData darkTheme = const .dark();
        return switch (snapshot.data!) {
          true => DynamicColorBuilder(
            builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
              if (lightDynamic != null && darkDynamic != null) {
                theme = theme.copyWith(colorScheme: lightDynamic);
                darkTheme = theme.copyWith(colorScheme: darkDynamic);
              }
              return _buildThemeModel(theme, darkTheme);
            },
          ),
          false => _buildThemeModel(theme, darkTheme),
          _ => const Text('dynamic color preference loading...'),
        };
      },
    )
  }
  
  Widget _buildThemeModel(ThemeModel theme, ThemeModel darkTheme) {
    return StreamBuilder(
      stream: themeConfig,
      builder: (_, snapshot) {
        return switch (snapshot.data!) {
          .followSystem => builder(theme, darkTheme, .system),
          .light => builder(theme, darkTheme, .light),
          .dark => builder(theme, darkTheme, .dark),
          _ => const Text('Theme model loading...'),
        }
      },
    );
  }
}
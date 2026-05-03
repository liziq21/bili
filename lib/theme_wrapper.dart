import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/model/user_data.dart';
import 'app_view_model.dart';

typedef ThemeBuilder =
    Widget Function(ThemeData theme, ThemeData darkTheme, ThemeMode themeModel);

class ThemeWrapper extends StatelessWidget {
  const ThemeWrapper({super.key, required this.builder});
  final ThemeBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Selector<AppViewModel, ThemeState>(
      selector: (_, vm) =>
          ThemeState(vm.userData.useDynamicColor, vm.userData.themeConfig),
      builder: (_, state, __) => _ThemeCore(state: state, builder: builder),
    );
  }
}

class _ThemeCore extends StatelessWidget {
  final ThemeState state;
  final ThemeBuilder builder;

  const _ThemeCore({required this.state, required this.builder});

  @override
  Widget build(BuildContext context) {
    final baseLight = ThemeData.light();
    final baseDark = ThemeData.dark();
    final themeMode = _convertToThemeMode(state.themeConfig);

    if (state.useDynamicColor) {
      return DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          final theme = lightDynamic != null
              ? baseLight.copyWith(colorScheme: lightDynamic)
              : baseLight;
          final darkTheme = darkDynamic != null
              ? baseDark.copyWith(colorScheme: darkDynamic)
              : baseDark;
          return builder(theme, darkTheme, themeMode);
        },
      );
    }

    return builder(baseLight, baseDark, themeMode);
  }

  ThemeMode _convertToThemeMode(ThemeConfig config) {
    return switch (config) {
      .followSystem => .system,
      .light => .light,
      .dark => .dark,
    };
  }
}

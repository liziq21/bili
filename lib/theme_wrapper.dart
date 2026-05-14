import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_view_model.dart';

typedef ThemeBuilder =
    Widget Function(ThemeData theme, ThemeData darkTheme, ThemeMode themeModel);

class ThemeWrapper extends StatelessWidget {
  final ThemeBuilder builder;
  const ThemeWrapper({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Selector<AppViewModel, ThemeState>(
      builder: (_, state, __) => _ThemeCore(state: state, builder: builder),
      selector: (_, vm) =>
          ThemeState(vm.userData.useDynamicColor, vm.userData.themeConfig),
    );
  }
}

class _ThemeCore extends StatelessWidget {
  const _ThemeCore({required this.state, required this.builder});

  final ThemeState state;
  final ThemeBuilder builder;

  @override
  Widget build(BuildContext context) {
    final baseLight = ThemeData.light();
    final baseDark = ThemeData.dark();
    // ignore: omit_local_variable_types
    final ThemeMode themeMode = switch (state.themeConfig) {
      .followSystem => .system,
      .light => .light,
      .dark => .dark,
    };

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
}

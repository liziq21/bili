import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_bloc.dart';
import 'feature/theme/bloc/theme_state.dart';

typedef ThemeBuilder = Widget Function(
  ThemeData theme,
  ThemeData darkTheme,
  ThemeMode themeModel,
);

class ThemeWrapper extends StatelessWidget {
  const ThemeWrapper({super.key, required this.builder});
  final ThemeBuilder builder;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AppBloc, AppState, ThemeState>(
      selector: (state) {
        state as LoadSuccess;
        return ThemeState(
          state.userData.useDynamicColor,
          state.userData.themeConfig,
        );
      },
      builder: (_, state) => _ThemeCore(state: state, builder: builder),
    );
  }
}

class _ThemeCore extends StatelessWidget {
  const _ThemeCore({required this.state, required this.builder});

  final ThemeState state;
  final ThemeBuilder builder;

  static final baseLight = ThemeData.light();
  static final baseDark = ThemeData.dark();

  @override
  Widget build(BuildContext context) {
    final ThemeMode themeMode = switch (state.themeConfig) {
      .followSystem => .system,
      .light => .light,
      .dark => .dark,
    };

    if (state.useDynamicColor) {
      return DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) => _buildWithDynamicColor(
          lightDynamic: lightDynamic,
          darkDynamic: darkDynamic,
          themeMode: themeMode,
        ),
      );
    }

    return builder(baseLight, baseDark, themeMode);
  }

  Widget _buildWithDynamicColor({
    required ColorScheme? lightDynamic,
    required ColorScheme? darkDynamic,
    required ThemeMode themeMode,
  }) {
    final theme = lightDynamic != null
        ? baseLight.copyWith(colorScheme: lightDynamic)
        : baseLight;
    final darkTheme = darkDynamic != null
        ? baseDark.copyWith(colorScheme: darkDynamic)
        : baseDark;

    return builder(theme, darkTheme, themeMode);
  }
}

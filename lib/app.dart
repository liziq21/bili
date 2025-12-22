import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_debug_overlay/flutter_debug_overlay.dart';
//import 'package:logger/logger.dart' hide LogEvent;
import 'package:provider/provider.dart';

import 'feature/view_model/theme_view_model.dart';

import 'routing/router.dart';

class App extends StatelessWidget {
  const App({super.key});

  static final LogBucket logBucket = LogBucket();
  static final HttpBucket httpBucket = HttpBucket();
  
  @override
  Widget build(BuildContext context) {
    final ThemeViewModel viewModel = context.read();
    
    return ListenableBuilder(
      listenable: viewModel.loadDynamicColor,
      builder: (_, _) => DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          ThemeData theme = .light();
          ThemeData darkTheme = .dark();
          if (
            viewModel.useDynamicColor &&
            lightDynamic != null &&
            darkDynamic != null
          ) {
            theme = theme.copyWith(colorScheme: lightDynamic);
            darkTheme = theme.copyWith(colorScheme: darkDynamic);
          }
          return ListenableBuilder(
            listenable: viewModel.loadThemeConfig,
            builder: (_, _) => MaterialApp.router(
              builder: (context, child) => DebugOverlay(
                logBucket: App.logBucket,
                httpBucket: App.httpBucket,
                child: child ?? const SizedBox.shrink(),
              ),
              debugShowCheckedModeBanner: false,
              showPerformanceOverlay: false,
              theme: theme,
              darkTheme: darkTheme,
              themeMode: switch (viewModel.themeConfig) {
                .followSystem => .system,
                .light => .light,
                .dark => .dark,
              },
              routerConfig: router,
            ),
          );
        },
      ),
    );
  }
}


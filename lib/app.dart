import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_debug_overlay/flutter_debug_overlay.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_size/window_size.dart';

import 'app_view_model.dart';
import 'l10n/localization_file/app_localizations.dart';
import 'routing/router.dart';
import 'theme_wrapper.dart';

const double windowWidth = 360;
const double windowHeight = 640;

void setupWindow() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    WidgetsFlutterBinding.ensureInitialized();
    setWindowTitle('');
    setWindowMinSize(const Size(windowWidth, windowHeight));
    setWindowMaxSize(const Size(windowWidth, windowHeight));
    getCurrentScreen().then((screen) {
      setWindowFrame(
        Rect.fromCenter(
          center: screen!.frame.center,
          width: windowWidth,
          height: windowHeight,
        ),
      );
    });
  }
}

class App extends StatelessWidget {
  const App({super.key, required this.viewModel});

  static final LogBucket logBucket = LogBucket();
  static final HttpBucket httpBucket = HttpBucket();

  final AppViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel.load,
      builder: (_, child) {
        if (viewModel.load.running) {
          return const Center(child: CircularProgressIndicator());
        }
        //if (viewModel.load.error)
        return child!;
      },
      child: ThemeWrapper(
        builder: (ThemeData theme, ThemeData darkTheme, ThemeMode themeMode) {
          return MaterialApp.router(
            builder: (_, child) => DebugOverlay(
              logBucket: App.logBucket,
              httpBucket: App.httpBucket,
              child: child ?? const SizedBox.shrink(),
            ),
            debugShowCheckedModeBanner: false,
            showPerformanceOverlay: false,
            theme: theme,
            darkTheme: darkTheme,
            themeMode: themeMode,
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            localeResolutionCallback: (locale, _) => locale,
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_debug_overlay/flutter_debug_overlay.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_view_model.dart';
import 'routing/router.dart';
import 'theme/theme_wrapper.dart';

const double windowWidth = 360;
const double windowHeight = 640;

void setupWindow() {
  if (!kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
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
  const App({this.viewModel, super.key});

  static final LogBucket logBucket = LogBucket();
  static final HttpBucket httpBucket = HttpBucket();
  
  final AppViewModel viewModel;
  
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (_, _) {
        return switch (viewModel.uiState) {
          .loading() => const Text('App loading...'),
          .success(final shouldUseDynamicColor, final themeConfig) =>
            ThemeWrapper(
              useDynamicColor: shouldUseDynamicColor
              themeConfig: themeConfig,
              builder: (ThemeData theme, ThemeData darkTheme, ThemeMode themeMode) {
                return MaterialApp.router(
                  builder: (context, child) => DebugOverlay(
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
              }
            ),
        }
    );
  }
}


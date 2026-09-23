import 'dart:io';

import 'package:bilibili/bilibili.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    as flutter_localizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_debug_overlay/flutter_debug_overlay.dart';
import 'package:window_size/window_size.dart';
import 'package:youtube/youtube.dart';

import 'app_bloc.dart';
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

class const App({super.key}) extends StatelessWidget {
  static final LogBucket logBucket = LogBucket();
  static final HttpBucket httpBucket = HttpBucket();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (_, state) => switch (state) {
        Loading() => const Center(child: CircularProgressIndicator()),
        LoadFailure() => const Text('应用加载失败，请重试'),
        LoadSuccess(:final userData) => ThemeWrapper(
          useDynamicColor: userData.useDynamicColor,
          themeConfig: userData.themeConfig,
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
              localizationsDelegates: const [
                ...AppLocalizations.localizationsDelegates,
                ...GlobalMaterialLocalizations.delegates,
                BilibiliLocalizations.delegate,
                YoutubeLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              localeResolutionCallback: (locale, supportedLocales) {
                if (locale != null) {
                  for (final supportedLocale in supportedLocales) {
                    if (supportedLocale.languageCode == locale.languageCode) {
                      return supportedLocale;
                    }
                  }
                }
                return AppLocalizations.supportedLocales.first;
              },
            );
          },
        ),
      },
    );
  }
}

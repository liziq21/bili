//import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_debug_overlay/flutter_debug_overlay.dart';
import 'package:logger/logger.dart' hide LogEvent;

import 'routing/router.dart';


class App extends StatefulWidget {
  const App({super.key});

  static final LogBucket logBucket = LogBucket();
  static final HttpBucket httpBucket = HttpBucket();

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      builder: (context, child) => DebugOverlay(
        //hiddenFields: const [HttpHeaders.authorizationHeader, "Token"],
        logBucket: App.logBucket,
        httpBucket: App.httpBucket,
        //debugEntries: [],
        child: child ?? const SizedBox.shrink(),
      ),
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false,
      theme: .light(),
      darkTheme: .dark(),
      themeMode: .system,
      routerConfig: router,
    );
  }
}


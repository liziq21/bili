import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_debug_overlay/flutter_debug_overlay.dart';
import 'package:logger/logger.dart' hide LogEvent;
import 'package:provider/provider.dart';

import 'app.dart';
import 'dependencies.dart';

Future<void> main() async {
  // Enables the debug overlay even in release mode.
  DebugOverlay.enabled = true;
  
  // Uncaught Exceptions.
  PlatformDispatcher.instance.onError = (exception, stackTrace) {
    App.logBucket.add(LogEvent(
      level: LogLevel.fatal,
      message: "Unhandled Exception",
      error: exception,
      stackTrace: stackTrace,
    ));
    return false;
  };

  // Rendering Exceptions.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    App.logBucket.add(LogEvent(
      level: LogLevel.fatal,
      message: details.exceptionAsString(),
      error: (kDebugMode
          ? details.toDiagnosticsNode().toStringDeep()
          : details.exception.toString()),
      stackTrace: details.stack,
    ));
  };

  // Connects logger to the overlay.
  Logger.addOutputListener((event) {
    LogLevel? level = LogLevel.values
        .firstWhereOrNull((element) => element.name == event.origin.level.name);
    if (level == null) return;
    App.logBucket.add(LogEvent(
      level: level,
      message: event.origin.message,
      error: event.origin.error,
      stackTrace: event.origin.stackTrace,
      time: event.origin.time,
    ));
  });
  
  runApp(const App());
}

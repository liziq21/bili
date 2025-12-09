import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:collection/collection.dart';import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_debug_overlay/flutter_debug_overlay.dart';
//import 'package:logger/logger.dart' hide LogEvent;
import 'package:logging/logging.dart';
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

  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    LogLevel? level = switch (record.level) {
      .OFF => .off,
      .FINEST || .FINER => .trace,
      .FINE || .SHOUT => .debug,
      .CONFIG || .INFO => .info,
      .WARNING => .warning,
      .SEVERE => .error,
      .ALL => .all,
      .LEVELS => null,
    }
    
    if (level == null) return;
    App.logBucket.add(LogEvent(
      level: level,
      message: '${record.loggerName} ${record.message}',
      error: record.error,
      stackTrace: record.stackTrace,
      time: record.time,
    ));
  });
  /*Logger.addOutputListener((event) {
    LogLevel? level = LogLevel.values
        .firstWhereOrNull((element) => element.name == event.level.name);
    if (level == null) return;
    App.logBucket.add(LogEvent(
      level: level,
      message: event.origin.message,
      error: event.origin.error,
      stackTrace: event.origin.stackTrace,
      time: event.origin.time,
    ));
  });*/
  
  runApp(
    MultiProvider(
      providers: providers,
      child: const App()
    ),
  );
}

import 'dart:async';

// import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
    App.logBucket.add(
      LogEvent(
        level: LogLevel.fatal,
        message: 'Unhandled Exception',
        error: exception,
        stackTrace: stackTrace,
      ),
    );
    return false;
  };

  // Rendering Exceptions.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    App.logBucket.add(
      LogEvent(
        level: LogLevel.fatal,
        message: details.exceptionAsString(),
        error: (kDebugMode
            ? details.toDiagnosticsNode().toStringDeep()
            : details.exception.toString()),
        stackTrace: details.stack,
      ),
    );
  };

  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    // ignore: omit_local_variable_types
    final LogLevel? level = switch (record.level) {
      Level.OFF => .off,
      Level.FINEST || .FINER => .trace,
      Level.FINE || .SHOUT => .debug,
      Level.CONFIG || .INFO => .info,
      Level.WARNING => .warning,
      Level.SEVERE => .error,
      Level.ALL => .all,
      _ => null,
    };

    if (level == null) return;
    App.logBucket.add(
      LogEvent(
        level: level,
        message: '${record.loggerName} ${record.message}',
        error: record.error,
        stackTrace: record.stackTrace,
        time: record.time,
      ),
    );
  });

  runApp(
    MultiProvider(
      providers: providers,
      child: Builder(
        builder: (context) {
          return App(viewModel: context.read());
        },
      ),
    ),
  );

  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }
}

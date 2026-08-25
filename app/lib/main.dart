import 'package:bilibili/bilibili.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_debug_overlay/flutter_debug_overlay.dart';
import 'package:http/io_client.dart' as http;
import 'package:logging/logging.dart';

import 'app.dart';
import 'providers/bloc_providers.dart';
import 'providers/repo_providers.dart';

void main() {
  initDebugOverlayBridge();

  runApp(
    MultiRepositoryProvider(
      providers: repoProviders,
      child: Builder(
        builder: (context) => MultiBlocProvider(
          providers: getBlocProviders(context),
          child: App(),
        ),
      ),
    ),
  );

  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }
}

void initDebugOverlayBridge() {
  DebugOverlay.enabled = true;

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
  Bili.client = HttpLogClient(
    App.httpBucket,
    http.IOClient(
      .new()
        //..findProxy = ((_) => 'PROXY 127.0.0.1:9000')
        ..badCertificateCallback = (_, _, _) => true,
    ),
  );
}

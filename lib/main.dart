import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'dependencies.dart';

Future<void> main() async {

  // https://docs.sentry.io/platforms/flutter/usage/#tips-for-catching-errors
  // https://docs.flutter.dev/testing/errors#errors-caught-by-flutter
  FlutterError.onError = (errorDetails) async {
    Logger().e(errorDetails.exception);
    await Sentry.captureException(errorDetails.exception, stackTrace: errorDetails.stack);
  };

  // https://github.com/getsentry/sentry-dart/tree/6.18.1/flutter#usage
  // https://docs.flutter.dev/testing/errors#errors-not-caught-by-flutter
  PlatformDispatcher.instance.onError = (error, stack) {
    Sentry.captureException(error, stackTrace: stack);
    return true;
  };
  
  // https://docs.sentry.io/platforms/flutter/#configure
  // https://pub.dev/documentation/sentry/latest/sentry_io/SentryOptions-class.html
  await SentryFlutter.init(
    (options) {
      options
        ..dsn = const String.fromEnvironment('SENTRY_DSN')
        ..sendDefaultPii = true;
    },
    appRunner: () => runApp(
      SentryWidget(
        child: MultiProvider(
          providers: providers,
          child: const App(),
        ),
      ),
    ),
  );
}

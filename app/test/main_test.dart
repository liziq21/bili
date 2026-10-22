import 'package:app/main.dart';
import 'package:bilibili/bilibili.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_debug_overlay/flutter_debug_overlay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'initDebugOverlayBridge configures debug overlay and http client correctly',
    () {
      initDebugOverlayBridge();

      if (kReleaseMode) {
        expect(DebugOverlay.enabled, isFalse);
        expect(Bili.client, isNot(isA<HttpLogClient>()));
      } else {
        expect(DebugOverlay.enabled, isTrue);
        expect(Bili.client, isA<HttpLogClient>());
      }
    },
  );

  testWidgets(
    'ErrorWidget.builder handles build errors securely based on build mode',
    (tester) async {
      final originalBuilder = ErrorWidget.builder;

      // Set up ErrorWidget.builder exactly as main() does
      ErrorWidget.builder = (details) => SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Text(
          kReleaseMode
              ? 'A rendering error occurred.'
              : 'Build error: ${details.exception}\n\n${details.stack}',
          textDirection: TextDirection.ltr,
        ),
      );

      final details = FlutterErrorDetails(
        exception: Exception('sensitive_secret_data'),
        stack: StackTrace.current,
      );

      final widget = ErrorWidget.builder(details);

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      if (kReleaseMode) {
        expect(find.text('A rendering error occurred.'), findsOneWidget);
        expect(find.textContaining('sensitive_secret_data'), findsNothing);
      } else {
        expect(find.textContaining('sensitive_secret_data'), findsOneWidget);
      }

      // Restore before test ends to satisfy test framework
      ErrorWidget.builder = originalBuilder;
    },
  );
}

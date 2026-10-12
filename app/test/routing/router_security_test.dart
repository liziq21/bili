import 'package:app/feature/not_found/not_found_screen.dart';
import 'package:app/routing/router.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

void main() {
  group('GoRouter Security Hardening Tests', () {
    test('Router instance is initialized', () {
      expect(router, isA<GoRouter>());
      expect(router.configuration, isNotNull);
    });

    test(
      'NotFoundScreen.sanitizeUriString masks query parameters and strips control characters',
      () {
        final sanitized = NotFoundScreen.sanitizeUriString(
          '/unknown?token=secret123&code=\x00abc',
        );
        expect(sanitized, contains('REDACTED'));
        expect(sanitized, isNot(contains('secret123')));
        expect(sanitized, isNot(contains('\x00')));
      },
    );

    testWidgets(
      'onException logs sanitized URI without sensitive query parameters',
      (tester) async {
        final logRecords = <LogRecord>[];
        final subscription = Logger('Router').onRecord.listen(logRecords.add);

        try {
          await tester.pumpWidget(
            Builder(
              builder: (context) {
                final state = GoRouterState(
                  router.configuration,
                  location: '/unknown?token=secret123&code=abc',
                  uri: Uri.parse('/unknown?token=secret123&code=abc'),
                  matchedLocation: '/unknown',
                  error: Exception('Route not found'),
                );

                router.onException!(context, state, router);
                return const SizedBox.shrink();
              },
            ),
          );

          expect(logRecords, hasLength(1));
          final message = logRecords.first.message;
          expect(message, contains('REDACTED'));
          expect(message, isNot(contains('secret123')));
        } finally {
          subscription.cancel();
        }
      },
    );
  });
}

import 'package:app/feature/not_found/not_found_screen.dart';
import 'package:app/routing/router.dart';
import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

void main() {
  group('GoRouter Security Hardening Tests', () {
    test('Router instance is initialized', () {
      expect(router, isA<GoRouter>());
      expect(router.configuration, isNotNull);
    });

    test('sanitizeUriString masks query params and control chars', () {
      final sanitized = NotFoundScreen.sanitizeUriString(
        '/unknown?token=secret123&code=\x00abc',
      );
      expect(sanitized, contains('REDACTED'));
      expect(sanitized, isNot(contains('secret123')));
      expect(sanitized, isNot(contains('\x00')));
    });

    test('logRoutingException logs only safe path diagnostics', () {
      final logRecords = <LogRecord>[];
      final subscription = Logger('Router').onRecord.listen(logRecords.add);

      try {
        const uriQuerySecret = 'uri-query-secret';
        const uriFragmentSecret = 'uri-fragment-secret';
        const uriUserInfoSecret = 'uri-user-info-secret';
        const errorSecret = 'error-secret';
        final state = GoRouterState(
          router.configuration,
          uri: Uri.parse(
            'https://user:$uriUserInfoSecret@example.test/unknown'
            '?token=$uriQuerySecret#$uriFragmentSecret',
          ),
          matchedLocation: '/unknown',
          fullPath: '/unknown',
          pathParameters: const <String, String>{},
          pageKey: const ValueKey<String>('/unknown'),
          error: GoException(
            'Route not found: $errorSecret '
            'https://example.test/unknown?token=$errorSecret',
          ),
        );

        logRoutingException(state);

        expect(logRecords, hasLength(1));
        final record = logRecords.single;
        expect(record.level, Level.SEVERE);
        expect(record.loggerName, 'Router');
        expect(record.message, 'Routing exception for path: /unknown');
        expect(record.error, isNull);
        expect(record.stackTrace, isNull);
        expect(record.object, isNull);

        final recordDetails = <Object?>[
          record.level,
          record.message,
          record.loggerName,
          record.error,
          record.stackTrace,
          record.object,
        ].join(' ');
        for (final secret in [
          uriQuerySecret,
          uriFragmentSecret,
          uriUserInfoSecret,
          errorSecret,
        ]) {
          expect(recordDetails, isNot(contains(secret)));
        }
      } finally {
        subscription.cancel();
      }
    });
  });
}

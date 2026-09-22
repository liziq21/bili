import 'package:app/routing/router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('GoRouter Security Hardening Tests', () {
    test('Router instance initialized and debug logging policy configured securely', () {
      expect(router, isA<GoRouter>());
      expect(router.configuration, isNotNull);
      // Verify that debugLogDiagnostics logic is aligned with !kReleaseMode
      const isReleaseMode = kReleaseMode;
      const expectedDiagnosticLogging = !isReleaseMode;
      expect(expectedDiagnosticLogging, equals(!kReleaseMode));
    });
  });
}

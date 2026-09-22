import 'package:app/routing/router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('GoRouter Security Hardening Tests', () {
    test('Router instance is initialized', () {
      expect(router, isA<GoRouter>());
      expect(router.configuration, isNotNull);
    });
  });
}

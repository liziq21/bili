import 'package:app/feature/not_found/not_found_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('NotFoundScreen Security Tests', () {
    testWidgets(
      'masks query parameters and sensitive credentials in deep links',
      (tester) async {
        const sensitiveUri =
            'https://app.bilibili.com/auth/callback?token=secret123&auth=bearer_abc';
        const samplePath = '/auth/callback';

        await tester.pumpWidget(
          const MaterialApp(
            home: NotFoundScreen(uri: sensitiveUri, path: samplePath),
          ),
        );

        await tester.pump();

        expect(find.textContaining('secret123'), findsNothing);
        expect(find.textContaining('bearer_abc'), findsNothing);
        expect(find.textContaining('token=REDACTED'), findsOneWidget);
        expect(find.textContaining('auth=REDACTED'), findsOneWidget);
      },
    );

    testWidgets('strips non-printable control characters from uri and path', (
      tester,
    ) async {
      const dirtyUri = 'https://app.bilibili.com/test\x00\x1F?id=123';
      const dirtyPath = '/test\x07\x00';

      await tester.pumpWidget(
        const MaterialApp(
          home: NotFoundScreen(uri: dirtyUri, path: dirtyPath),
        ),
      );

      await tester.pump();

      expect(find.textContaining('\x00'), findsNothing);
      expect(find.textContaining('\x1F'), findsNothing);
      expect(find.textContaining('\x07'), findsNothing);
    });
  });
}

import 'package:app/feature/not_found/not_found_screen.dart';
import 'package:app/l10n/localization_file/app_localizations_en.dart';
import 'package:app/l10n/localization_file/app_localizations_zh.dart';
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
          MaterialApp(
            home: NotFoundScreen(
              uri: sensitiveUri,
              path: samplePath,
              l10n: AppLocalizationsEn(),
            ),
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
        MaterialApp(
          home: NotFoundScreen(
            uri: dirtyUri,
            path: dirtyPath,
            l10n: AppLocalizationsEn(),
          ),
        ),
      );

      await tester.pump();

      expect(find.textContaining('\x00'), findsNothing);
      expect(find.textContaining('\x1F'), findsNothing);
      expect(find.textContaining('\x07'), findsNothing);
    });

    testWidgets('renders Chinese copy when AppLocalizations is zh', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotFoundScreen(
            uri: 'https://example.com/missing',
            path: '/missing',
            l10n: AppLocalizationsZh(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('页面不存在'), findsOneWidget);
      expect(find.textContaining('找不到这个页面'), findsOneWidget);
    });
  });
}

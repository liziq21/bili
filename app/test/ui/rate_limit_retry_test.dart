import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:app/l10n/localization_file/app_localizations_zh.dart';
import 'package:app/ui/common/rate_limit_retry.dart';
import 'package:bilibili/bilibili.dart' show BiliRiskControlException;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('isRateLimited only accepts the risk-control rejection', () {
    expect(isRateLimited(const BiliRiskControlException('blocked')), isTrue);
    expect(isRateLimited(Exception('boom')), isFalse);
    expect(isRateLimited(null), isFalse);
  });

  Future<void> pumpButton(
    WidgetTester tester, {
    required bool rateLimited,
    required VoidCallback onRetry,
    Duration cooldown = const Duration(seconds: 3),
  }) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: RetryCooldownButton(
          rateLimited: rateLimited,
          cooldown: cooldown,
          onRetry: onRetry,
        ),
      ),
    ),
  );

  testWidgets('a plain failure keeps retry usable', (tester) async {
    var retried = 0;
    await pumpButton(tester, rateLimited: false, onRetry: () => retried++);

    expect(find.text(AppLocalizationsZh().retry), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(retried, 1);
  });

  testWidgets('a rate-limited failure blocks retry until the cooldown ends', (
    tester,
  ) async {
    var retried = 0;
    await pumpButton(tester, rateLimited: true, onRetry: () => retried++);

    final l10n = AppLocalizationsZh();
    expect(find.text(l10n.retryInSeconds(3)), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(retried, 0);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text(l10n.retryInSeconds(2)), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text(l10n.retry), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(retried, 1);
    // 重试又失败时按钮重新进入冷静期，而不是让用户连点。
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
}

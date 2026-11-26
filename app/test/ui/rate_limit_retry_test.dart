import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:app/l10n/localization_file/app_localizations_zh.dart';
import 'package:app/ui/common/rate_limit_retry.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class const _RateLimited() implements RateLimitedFailure;

void main() {
  test('escalates the cooldown for consecutive rejections and caps it', () {
    // Given a scope that keeps getting rejected.
    const scope = 'test.escalation';

    // Then the cooldown doubles from the base value and never exceeds the cap.
    expect(rateLimitCooldownFor(scope), rateLimitRetryBaseCooldown);
    expect(rateLimitCooldownFor(scope), const Duration(seconds: 30));
    expect(rateLimitCooldownFor(scope), const Duration(minutes: 1));
    for (var i = 0; i < 8; i++) {
      rateLimitCooldownFor(scope);
    }
    expect(rateLimitCooldownFor(scope), rateLimitRetryMaxCooldown);

    // When the next attempt succeeds, the streak is forgotten.
    resetRateLimitCooldown(scope);
    expect(rateLimitCooldownFor(scope), rateLimitRetryBaseCooldown);
  });

  test('isRateLimited only accepts the neutral rate-limit failure', () {
    expect(isRateLimited(const _RateLimited()), isTrue);
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

  testWidgets('remounting the same rejection does not escalate the cooldown', (
    tester,
  ) async {
    // 切走再回到同一个被限流的列表会重新挂载组件，这不是新的一次拒绝。
    const scope = 'test.remount';
    const cooldown = Duration(seconds: 3);
    final failure = Exception('limited');
    Future<void> pumpOnce() => tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: RetryCooldownButton(
            rateLimited: true,
            cooldown: cooldown,
            scope: scope,
            failure: failure,
            onRetry: () {},
          ),
        ),
      ),
    );

    await pumpOnce();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await pumpOnce();

    expect(
      find.text(AppLocalizationsZh().retryInSeconds(cooldown.inSeconds)),
      findsOneWidget,
    );
  });

  testWidgets('a new rejection escalates the cooldown', (tester) async {
    const scope = 'test.newRejection';
    var failure = Exception('limited');
    Future<void> pumpOnce() => tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: RetryCooldownButton(
            rateLimited: true,
            scope: scope,
            failure: failure,
            onRetry: () {},
          ),
        ),
      ),
    );

    await pumpOnce();
    expect(
      find.text(
        AppLocalizationsZh().retryInSeconds(
          rateLimitRetryBaseCooldown.inSeconds,
        ),
      ),
      findsOneWidget,
    );

    // 换了一个失败对象 = 又收到一次拒绝，冷却翻倍。
    failure = Exception('limited again');
    await pumpOnce();
    await tester.pump();

    expect(
      find.text(
        AppLocalizationsZh().retryInSeconds(
          rateLimitRetryBaseCooldown.inSeconds * 2,
        ),
      ),
      findsOneWidget,
    );
  });
}

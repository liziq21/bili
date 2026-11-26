import 'package:app/feature/home/widgets/feed_status_view.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:data/data.dart' show RateLimitedFailure;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class const _RateLimited() implements RateLimitedFailure {
  @override
  String toString() => 'rate limited';
}

void main() {
  testWidgets(
    'FeedStatusView renders message, description and triggers onRetry',
    (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedStatusView(
              icon: Icons.error_outline,
              message: '网络错误',
              description: '请重试',
              onRetry: () {
                retried = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('网络错误'), findsOneWidget);
      expect(find.text('请重试'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      expect(retried, isTrue);
    },
  );

  testWidgets('FeedStatusView.failure factory constructor renders correctly', (
    tester,
  ) async {
    bool retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedStatusView.failure(
            title: '推荐 Feed',
            onRetry: () {
              retried = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('推荐 Feed failed'), findsOneWidget);
    expect(find.text('Check your connection and retry'), findsOneWidget);

    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();

    expect(retried, isTrue);
  });

  testWidgets(
    'FeedStatusView.failure names rate limiting and cools the retry down',
    (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: FeedStatusView.failure(
              title: '推荐 Feed',
              error: const _RateLimited(),
              retryScope: 'test.feed_status_view.rate_limited',
              onRetry: () {
                retried = true;
              },
            ),
          ),
        ),
      );

      // 限流不是断网：文案要说清是请求过快，重试按钮在冷静期内不可点。
      expect(find.text('操作过快，请稍后再试'), findsOneWidget);
      expect(find.text('请检查网络连接后重试'), findsNothing);
      expect(find.textContaining('秒后可重试'), findsOneWidget);
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );

      await tester.pump(const Duration(seconds: 15));
      expect(find.text('重试'), findsOneWidget);

      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();
      expect(retried, isTrue);
    },
  );
}

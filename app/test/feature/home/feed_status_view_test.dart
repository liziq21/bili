import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:app/feature/home/widgets/feed_status_view.dart';

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
      expect(find.text('重试'), findsOneWidget);

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

    expect(find.text('推荐 Feed 加载失败'), findsOneWidget);
    expect(find.text('请检查网络连接后重试'), findsOneWidget);

    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();

    expect(retried, isTrue);
  });
}

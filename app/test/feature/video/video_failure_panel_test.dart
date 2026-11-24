import 'package:app/app_scaffold.dart';
import 'package:app/design/app_colors.dart';
import 'package:app/design/app_theme.dart';
import 'package:app/design/brand_palette.dart';
import 'package:app/feature/video/common_widgets/video_failure_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _wrap(Widget child, {ThemeMode mode = ThemeMode.light}) => MaterialApp(
  theme: appThemeData(AppColors(BrandPalette.of(Brightness.light))),
  darkTheme: appThemeData(AppColors(BrandPalette.of(Brightness.dark))),
  themeMode: mode,
  home: AppScaffold(child: Scaffold(body: child)),
);

void main() {
  testWidgets('shows the message and runs retry', (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      _wrap(
        SizedBox(
          height: 400,
          child: VideoFailurePanel(
            message: 'Failed to load',
            retryLabel: 'Retry',
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    expect(find.text('Failed to load'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(retries, 1);
  });

  testWidgets('a panel too short for its content can still be retried', (
    tester,
  ) async {
    // 矮横屏：详情/评论面板只剩一百多 dp，居中且不可滚动的 Column 会把
    // 重试按钮推到面板之外，用户点不到也就无法恢复。
    var retries = 0;

    await tester.pumpWidget(
      _wrap(
        SizedBox(
          height: 110,
          child: VideoFailurePanel(
            message: 'Failed to load',
            retryLabel: 'Retry',
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    final button = find.byType(OutlinedButton);
    expect(
      tester.getRect(button).bottom,
      greaterThan(110),
      reason: 'precondition: 110dp is too short to fit the button, so this test only proves anything if it scrolls',
    );

    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();

    expect(retries, 1);
  });

  testWidgets('no retry entry when the caller cannot retry', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          height: 400,
          child: VideoFailurePanel(
            message: 'Failed to load',
            retryLabel: 'Retry',
          ),
        ),
      ),
    );

    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('the message colour follows the active theme', (tester) async {
    // 每次都新建子树：传同一个 const widget 时 Element.updateChild 会因
    // `child.widget == newWidget` 直接跳过重建，测不出配色是否跟着主题走。
    Widget panel() => SizedBox(
      height: 400,
      child: VideoFailurePanel(message: 'Failed to load', retryLabel: 'Retry'),
    );

    await tester.pumpWidget(_wrap(panel()));

    Color? messageColor() =>
        tester.widget<Text>(find.text('Failed to load')).style?.color;

    expect(messageColor(), BrandPalette.of(Brightness.light).errorText);

    await tester.pumpWidget(_wrap(panel(), mode: ThemeMode.dark));
    await tester.pumpAndSettle();

    expect(messageColor(), BrandPalette.of(Brightness.dark).errorText);
  });
}

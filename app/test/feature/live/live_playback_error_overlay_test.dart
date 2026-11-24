import 'package:app/feature/live/live_playback_error_overlay.dart';
import 'package:app/feature/video/player/playback_error.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _buildOverlay({
  PlaybackErrorCategory category = PlaybackErrorCategory.open,
  VoidCallback? onRetry,
  Locale locale = const Locale('zh'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      ...AppLocalizations.localizationsDelegates,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: LivePlaybackErrorOverlay(
        category: category,
        onRetry: onRetry ?? () {},
      ),
    ),
  );
}

void main() {
  testWidgets('shows the localized category instead of the raw error', (
    tester,
  ) async {
    await tester.pumpWidget(_buildOverlay());

    expect(find.text('无法打开播放地址'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('labels a network failure as a network error', (tester) async {
    await tester.pumpWidget(
      _buildOverlay(category: PlaybackErrorCategory.network),
    );

    expect(find.text('网络错误'), findsOneWidget);
  });

  testWidgets('tapping retry runs the callback', (tester) async {
    var retries = 0;

    await tester.pumpWidget(_buildOverlay(onRetry: () => retries++));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(retries, 1);
  });
}

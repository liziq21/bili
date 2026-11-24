import 'package:app/app_scaffold.dart';
import 'package:app/design/design.dart';
import 'package:app/feature/live/live_playback_error_overlay.dart';
import 'package:app/feature/video/player/playback_error.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _buildOverlay({
  PlaybackErrorCategory category = PlaybackErrorCategory.open,
  VoidCallback? onRetry,
  Locale locale = const Locale('zh'),
  Brightness brightness = Brightness.light,
  LivePlaybackErrorOverlay? overlay,
}) {
  return MaterialApp(
    theme: appThemeData(AppColors(BrandPalette.of(brightness))),
    locale: locale,
    localizationsDelegates: const [
      ...AppLocalizations.localizationsDelegates,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: AppScaffold(
      child: Scaffold(
        body:
            overlay ??
            LivePlaybackErrorOverlay(
              category: category,
              onRetry: onRetry ?? () {},
            ),
      ),
    ),
  );
}

Color _scrimColor(WidgetTester tester) => tester
    .widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(LivePlaybackErrorOverlay),
            matching: find.byType(ColoredBox),
          )
          .first,
    )
    .color;

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

  testWidgets('a signed stream URL in the error never reaches the screen', (
    tester,
  ) async {
    // Given a player failure whose text carries the signed live URL.
    final error = MediaPlaybackException.fromMessage(
      'Failed to open '
      'https://cdn.example.com/live/stream.m3u8?sign=abc123&expires=1700&trid=x',
    );

    // When the overlay renders that failure.
    await tester.pumpWidget(_buildOverlay(category: error.category));

    // Then only the localized category is on screen.
    expect(find.textContaining('sign='), findsNothing);
    expect(find.textContaining('cdn.example.com'), findsNothing);
    expect(find.textContaining(error.message), findsNothing);
  });

  testWidgets('the scrim follows the active theme', (tester) async {
    // Given a mounted overlay that keeps the same widget instance across the
    // theme switch, so only a theme dependency can rebuild it.
    const overlay = LivePlaybackErrorOverlay(
      category: PlaybackErrorCategory.open,
      onRetry: _noop,
    );

    await tester.pumpWidget(
      _buildOverlay(brightness: Brightness.light, overlay: overlay),
    );
    expect(
      _scrimColor(tester),
      BrandPalette.of(Brightness.light).scrim.withValues(alpha: 0.72),
    );

    // When the app switches to the dark theme. MaterialApp animates the
    // change, so settle before reading the painted colour.
    await tester.pumpWidget(
      _buildOverlay(brightness: Brightness.dark, overlay: overlay),
    );
    await tester.pumpAndSettle();

    // Then the scrim is repainted from the dark palette.
    expect(
      _scrimColor(tester),
      BrandPalette.of(Brightness.dark).scrim.withValues(alpha: 0.72),
    );
  });

  testWidgets('tapping retry runs the callback', (tester) async {
    var retries = 0;

    await tester.pumpWidget(_buildOverlay(onRetry: () => retries++));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(retries, 1);
  });
}

void _noop() {}

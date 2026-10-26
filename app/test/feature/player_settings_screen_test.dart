import 'package:app/app_scaffold.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/setting/app_settings.dart';
import 'package:app/feature/setting/player_settings_screen.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Widget _buildScreen(
  PreferencesDataSource preferences, {
  Locale locale = const Locale('zh'),
}) {
  return Provider<PreferencesDataSource>.value(
    value: preferences,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AppScaffold(child: PlayerSettingsScreen()),
    ),
  );
}

void main() {
  late PreferencesDataSource preferences;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = PreferencesDataSource(
      sharedPreferences: SharedPreferencesAsync(),
    );
  });

  tearDown(() => preferences.dispose());

  testWidgets('renders player settings with persisted defaults', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(PlayerSettingsScreen));
    final l10n = AppLocalizations.of(context)!;

    expect(find.widgetWithText(AppBar, l10n.settingsPlayer), findsOneWidget);
    expect(find.text(l10n.playerDefaultQuality), findsOneWidget);
    expect(find.text(l10n.playerDefaultSpeed), findsOneWidget);
    expect(find.text(l10n.playerSleepTimerDefault), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNWidgets(4));
    expect(find.text(l10n.playerQualityAuto), findsOneWidget);
    expect(find.text('1x'), findsOneWidget);
    expect(find.text(l10n.playerSleepTimerOff), findsOneWidget);
  });

  testWidgets('changes player values and writes them to preferences', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(PlayerSettingsScreen));
    final l10n = AppLocalizations.of(context)!;

    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pump();
    final gestures = await GestureSettings.load(preferences);
    expect(gestures.seekEnabled, isFalse);

    await tester.tap(find.text(l10n.playerDefaultQuality));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.playerQualityHeight('1080')));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.playerDefaultSpeed));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1.5x'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.playerSleepTimerDefault));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.minutesValue('30')));
    await tester.pumpAndSettle();

    final settings = await PlayerSettings.load(preferences);
    expect(settings.preferredQualityHeight, 1080);
    expect(settings.preferredQualityStreamId, isNull);
    expect(settings.playbackRate, 1.5);
    expect(settings.sleepTimerDefaultMinutes, 30);
  });

  testWidgets('uses English translations when English is selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildScreen(preferences, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(PlayerSettingsScreen));
    final l10n = AppLocalizations.of(context)!;

    expect(l10n.playerDefaultQuality, 'Default video quality');
    expect(l10n.playerGestures, 'Playback gestures');
    expect(find.text(l10n.playerDefaultQuality), findsOneWidget);
    expect(find.text('默认画质'), findsNothing);
  });
}

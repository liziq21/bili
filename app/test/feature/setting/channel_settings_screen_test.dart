import 'package:app/app_scaffold.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/setting/channel_settings_screen.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:app/l10n/localization_file/app_localizations_zh.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';
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
      home: const AppScaffold(child: ChannelSettingsScreen()),
    ),
  );
}

final class _FailingPreferencesDataSource({super.sharedPreferences})
    extends PreferencesDataSource {
  @override
  Future<Result<void, Exception>> set<T>(
    PreferencesKey<T> prefKey,
    T? value,
  ) async => Result.error(Exception('disk full'));
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

  group(ChannelSettingsScreen, () {
    testWidgets('shows the channel title and the videos switch enabled', (
      tester,
    ) async {
      // Given the localized channel settings page.
      await tester.pumpWidget(_buildScreen(preferences));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ChannelSettingsScreen));
      final l10n = AppLocalizations.of(context)!;

      // Then the page title and both implemented channel tabs are visible.
      expect(find.widgetWithText(AppBar, l10n.settingsChannel), findsOneWidget);
      expect(find.text(l10n.settingsChannelTabs), findsOneWidget);
      expect(
        find.text(l10n.settingsChannelTabVisibilitySubtitle),
        findsNWidgets(2),
      );
      expect(find.byType(SwitchListTile), findsNWidgets(2));
      final switchTile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, l10n.channelTabVideosVisibility),
      );
      expect(switchTile.value, isTrue);
      expect(find.text(l10n.channelTabVideosVisibility), findsOneWidget);
      expect(find.text(l10n.channelTabPlaylistsVisibility), findsOneWidget);
    });

    testWidgets('hides the videos tab and persists the choice', (tester) async {
      // Given the channel settings page with the videos tab visible.
      await tester.pumpWidget(_buildScreen(preferences));
      await tester.pumpAndSettle();

      // When turning the videos switch off.
      await tester.tap(
        find.widgetWithText(
          SwitchListTile,
          AppLocalizationsZh().channelTabVideosVisibility,
        ),
      );
      await tester.pumpAndSettle();

      // Then the switch reflects the change and the preference is stored.
      final switchTile = tester.widget<SwitchListTile>(
        find.widgetWithText(
          SwitchListTile,
          AppLocalizationsZh().channelTabVideosVisibility,
        ),
      );
      expect(switchTile.value, isFalse);
      final result = await preferences.get(PreferencesKey.channelTabVisibility);
      expect(
        (result as Success<String, Exception>).success,
        '{"videos":false}',
      );
    });

    testWidgets('hides the playlists tab and persists the choice', (
      tester,
    ) async {
      // Given the channel settings page with the playlists tab visible.
      await tester.pumpWidget(_buildScreen(preferences));
      await tester.pumpAndSettle();

      // When turning the playlists switch off.
      await tester.tap(
        find.widgetWithText(
          SwitchListTile,
          AppLocalizationsZh().channelTabPlaylistsVisibility,
        ),
      );
      await tester.pumpAndSettle();

      // Then the switch reflects the change and the preference is stored.
      final switchTile = tester.widget<SwitchListTile>(
        find.widgetWithText(
          SwitchListTile,
          AppLocalizationsZh().channelTabPlaylistsVisibility,
        ),
      );
      expect(switchTile.value, isFalse);
      final result = await preferences.get(PreferencesKey.channelTabVisibility);
      expect(
        (result as Success<String, Exception>).success,
        '{"playlists":false}',
      );
    });

    testWidgets('reverts the switch and reports a failed save', (tester) async {
      // Given the channel settings page backed by a failing preferences store.
      final failing = _FailingPreferencesDataSource(
        sharedPreferences: SharedPreferencesAsync(),
      );
      addTearDown(failing.dispose);
      await tester.pumpWidget(_buildScreen(failing));
      await tester.pumpAndSettle();

      final l10n = AppLocalizationsZh();
      final switchFinder = find.widgetWithText(
        SwitchListTile,
        l10n.channelTabPlaylistsVisibility,
      );

      // When turning the playlists switch off.
      await tester.tap(switchFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Then the optimistic change is reverted and the failure is surfaced.
      expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);
      expect(find.text(l10n.settingsSaveFailed), findsOneWidget);
    });

    testWidgets('reads a hidden tab from preferences', (tester) async {
      // Given a stored setting that hides the videos tab.
      await preferences.set(
        PreferencesKey.channelTabVisibility,
        '{"videos":false}',
      );

      // When rendering the settings page.
      await tester.pumpWidget(_buildScreen(preferences));
      await tester.pumpAndSettle();

      // Then the switch starts in the hidden state.
      final switchTile = tester.widget<SwitchListTile>(
        find.widgetWithText(
          SwitchListTile,
          AppLocalizationsZh().channelTabVideosVisibility,
        ),
      );
      expect(switchTile.value, isFalse);
    });

    testWidgets('uses English labels when English is selected', (tester) async {
      // Given the channel settings page under the English locale.
      await tester.pumpWidget(
        _buildScreen(preferences, locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      // Then the section and switch labels are English.
      expect(find.widgetWithText(AppBar, 'Channel'), findsOneWidget);
      expect(find.text('Channel page tabs'), findsOneWidget);
      expect(find.text('Show video tab'), findsOneWidget);
      expect(find.text('Show playlists tab'), findsOneWidget);
    });

    testWidgets('renders defaults without a preferences provider', (
      tester,
    ) async {
      // Given the page mounted without the application preferences provider.
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppScaffold(child: ChannelSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Then the page still renders with the default visible state.
      expect(find.byType(SwitchListTile), findsNWidgets(2));
      for (final tile in tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      )) {
        expect(tile.value, isTrue);
      }
    });
  });
}

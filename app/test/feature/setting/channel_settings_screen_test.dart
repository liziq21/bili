import 'package:app/app_scaffold.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/setting/channel_settings_screen.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
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

      // Then the page title and the only implemented channel tab are visible.
      expect(find.widgetWithText(AppBar, l10n.settingsChannel), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTile.value, isTrue);
      expect(find.text(l10n.videoTab), findsOneWidget);
    });

    testWidgets('hides the videos tab and persists the choice', (tester) async {
      // Given the channel settings page with the videos tab visible.
      await tester.pumpWidget(_buildScreen(preferences));
      await tester.pumpAndSettle();

      // When turning the videos switch off.
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      // Then the switch reflects the change and the preference is stored.
      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTile.value, isFalse);
      final result = await preferences.get(PreferencesKey.channelTabVisibility);
      expect(
        (result as Success<String, Exception>).success,
        '{"videos":false}',
      );
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
        find.byType(SwitchListTile),
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
      expect(find.text('Video'), findsOneWidget);
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
      expect(find.byType(SwitchListTile), findsOneWidget);
      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTile.value, isTrue);
    });
  });
}

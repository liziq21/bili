import 'package:app/app_scaffold.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/setting/common_widgets/setting_tiles.dart';
import 'package:app/feature/setting/notification_settings_screen.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Widget _buildScreen(PreferencesDataSource preferences) {
  return Provider<PreferencesDataSource>.value(
    value: preferences,
    child: MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AppScaffold(child: NotificationSettingsScreen()),
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

  group('NotificationSettingsScreen', () {
    testWidgets('shows the threshold as a value row, not a dropdown', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(preferences));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(NotificationSettingsScreen));
      final l10n = AppLocalizations.of(context)!;

      expect(find.byType(DropdownButton<int>), findsNothing);
      expect(
        find.descendant(
          of: find.byType(SettingValueTile),
          matching: find.text(l10n.feedUpdateThresholdOption(3)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('persists the threshold chosen in the picker', (tester) async {
      await tester.pumpWidget(_buildScreen(preferences));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(NotificationSettingsScreen));
      final l10n = AppLocalizations.of(context)!;

      await tester.tap(find.byType(SettingValueTile));
      await tester.pumpAndSettle();

      expect(find.text(l10n.feedUpdateThresholdOff), findsOneWidget);

      await tester.tap(
        find.widgetWithText(
          SettingPickerOption,
          l10n.feedUpdateThresholdOption(5),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(SettingValueTile),
          matching: find.text(l10n.feedUpdateThresholdOption(5)),
        ),
        findsOneWidget,
      );

      final result = await preferences.get(
        PreferencesKey.feedUpdateNotificationThreshold,
      );
      expect((result as Success<int, Exception>).success, 5);
    });
  });
}

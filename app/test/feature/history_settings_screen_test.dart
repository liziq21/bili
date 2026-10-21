import 'package:app/app_scaffold.dart';
import 'package:app/datastore/media_history_settings.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/setting/history_settings_screen.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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
      home: const AppScaffold(child: HistorySettingsScreen()),
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

  testWidgets('switches load and persist local history settings', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pumpAndSettle();

    final switches = find.byType(SwitchListTile);
    expect(switches, findsNWidgets(2));
    expect(tester.widget<SwitchListTile>(switches.at(0)).value, isTrue);
    expect(tester.widget<SwitchListTile>(switches.at(1)).value, isTrue);

    await tester.tap(switches.at(0));
    await tester.pump();
    await tester.tap(switches.at(1));
    await tester.pump();

    final settings = await MediaHistorySettings.load(preferences);
    expect(settings.recordHistory, isFalse);
    expect(settings.resumePlayback, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

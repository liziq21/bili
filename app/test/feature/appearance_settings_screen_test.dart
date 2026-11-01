import 'package:app/app_scaffold.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/setting/appearance_settings_screen.dart';
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
      home: const AppScaffold(child: AppearanceSettingsScreen()),
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

  group('AppearanceSettingsScreen', () {
    testWidgets('renders with default theme and font scale', (tester) async {
      await tester.pumpWidget(_buildScreen(preferences));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(AppearanceSettingsScreen));
      final l10n = AppLocalizations.of(context)!;

      expect(
        find.widgetWithText(AppBar, l10n.settingsAppearance),
        findsOneWidget,
      );
      expect(find.text(l10n.appearanceThemeSystem), findsOneWidget);
      expect(find.text(l10n.appearanceFontSizeStandard), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('changes theme and persists to preferences', (tester) async {
      await tester.pumpWidget(_buildScreen(preferences));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(AppearanceSettingsScreen));
      final l10n = AppLocalizations.of(context)!;

      // Tap theme tile to open picker (target the ListTile, not the section header).
      await tester.tap(find.byType(ListTile).at(0));
      await tester.pumpAndSettle();

      // Select Dark.
      await tester.tap(find.text(l10n.appearanceThemeDark));
      await tester.pumpAndSettle();

      // Value updates immediately.
      expect(find.text(l10n.appearanceThemeDark), findsOneWidget);

      // Persisted to preferences via the same PreferencesDataSource instance.
      final result = await preferences.get(PreferencesKey.themeConfig);
      expect((result as Success<String, Exception>).success, 'DARK');
    });

    testWidgets('changes font scale and persists to preferences', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(preferences));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(AppearanceSettingsScreen));
      final l10n = AppLocalizations.of(context)!;

      // Tap font size tile to open picker (target the ListTile, not the section header).
      await tester.tap(find.byType(ListTile).at(1));
      await tester.pumpAndSettle();

      // Select Large (1.15).
      await tester.tap(find.text(l10n.appearanceFontSizeLarge));
      await tester.pumpAndSettle();

      // Value updates immediately.
      expect(find.text(l10n.appearanceFontSizeLarge), findsOneWidget);

      // Persisted to preferences via the same PreferencesDataSource instance.
      final result = await preferences.get(PreferencesKey.fontScale);
      expect((result as Success<double, Exception>).success, 1.15);
    });

    testWidgets('uses English translations when English is selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildScreen(preferences, locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(AppearanceSettingsScreen));
      final l10n = AppLocalizations.of(context)!;

      expect(
        find.widgetWithText(AppBar, l10n.settingsAppearance),
        findsOneWidget,
      );
      expect(find.text(l10n.appearanceThemeSystem), findsOneWidget);
      expect(find.text(l10n.appearanceFontSizeStandard), findsOneWidget);
    });
  });
}

import 'package:app/app_scaffold.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/setting/library_settings_screen.dart';
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
      home: const AppScaffold(child: LibrarySettingsScreen()),
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

  group('LibrarySettingsScreen', () {
    testWidgets('renders with default bookmark sync and retention period', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(preferences));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LibrarySettingsScreen));
      final l10n = AppLocalizations.of(context)!;

      expect(find.widgetWithText(AppBar, l10n.settingsLibrary), findsOneWidget);
      expect(find.text(l10n.libraryBookmarkSync), findsWidgets);
      expect(find.text(l10n.librarySearchHistoryRetention), findsWidgets);
      expect(
        find.text(l10n.librarySearchHistoryRetention30Days),
        findsOneWidget,
      );
      expect(find.byType(SwitchListTile), findsOneWidget);
      expect(find.byType(DropdownButton<int>), findsOneWidget);
    });

    testWidgets('toggles bookmark sync switch and persists preference', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(preferences));
      await tester.pumpAndSettle();

      final switchFinder = find.byType(SwitchListTile);
      expect(switchFinder, findsOneWidget);

      final initialSwitch = tester.widget<SwitchListTile>(switchFinder);
      expect(initialSwitch.value, isTrue);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final updatedSwitch = tester.widget<SwitchListTile>(switchFinder);
      expect(updatedSwitch.value, isFalse);

      final result = await preferences.get(PreferencesKey.bookmarkSyncEnabled);
      expect((result as Success<bool, Exception>).success, isFalse);
    });

    testWidgets('changes search history retention and persists preference', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(preferences));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LibrarySettingsScreen));
      final l10n = AppLocalizations.of(context)!;

      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(l10n.librarySearchHistoryRetention90Days).last,
      );
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.librarySearchHistoryRetention90Days),
        findsOneWidget,
      );

      final result = await preferences.get(
        PreferencesKey.searchHistoryRetentionDays,
      );
      expect((result as Success<int, Exception>).success, 90);
    });

    testWidgets('verifies retention dropdown semantics and tooltips', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(preferences));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LibrarySettingsScreen));
      final l10n = AppLocalizations.of(context)!;

      final semanticsFinder = find.ancestor(
        of: find.byType(DropdownButton<int>),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == l10n.librarySearchHistoryRetention &&
              widget.properties.value ==
                  l10n.librarySearchHistoryRetention30Days &&
              widget.excludeSemantics == true,
        ),
      );
      expect(semanticsFinder, findsOneWidget);

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Tooltip &&
              widget.message ==
                  '${l10n.librarySearchHistoryRetention}: ${l10n.librarySearchHistoryRetention30Days}',
        ),
        findsOneWidget,
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Tooltip &&
              widget.message == '${l10n.libraryBookmarkSync}: ${l10n.confirm}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('uses English translations when English is selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildScreen(preferences, locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(LibrarySettingsScreen));
      final l10n = AppLocalizations.of(context)!;

      expect(l10n.libraryBookmarkSync, 'Sync bookmarks');
      expect(find.widgetWithText(AppBar, l10n.settingsLibrary), findsOneWidget);
      expect(find.text(l10n.libraryBookmarkSync), findsWidgets);
      expect(
        find.text(l10n.librarySearchHistoryRetention30Days),
        findsOneWidget,
      );
    });

    testWidgets('renders in isolated environment without preferences', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: AppScaffold(child: LibrarySettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LibrarySettingsScreen), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
      expect(find.byType(DropdownButton<int>), findsOneWidget);
    });
  });
}

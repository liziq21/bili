import 'package:app/app_scaffold.dart';
import 'package:app/feature/setting/advanced_settings_screen.dart';
import 'package:app/feature/setting/appearance_settings_screen.dart';
import 'package:app/feature/setting/library_settings_screen.dart';
import 'package:app/feature/setting/setting_screen.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _buildScreen(Widget child) => MaterialApp(
  locale: const Locale('zh'),
  localizationsDelegates: const [
    ...AppLocalizations.localizationsDelegates,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: AppScaffold(child: child),
);

void main() {
  const sections = [
    (SettingsSection.player, 'Player'),
    (SettingsSection.appearance, 'Appearance'),
    (SettingsSection.history, 'History'),
    (SettingsSection.library, 'Library'),
    (SettingsSection.advanced, 'Advanced'),
  ];

  group('SettingScreen', () {
    testWidgets('shows the settings title and exactly five groups in order', (
      tester,
    ) async {
      // Given the app's zh locale and both material localization delegates.
      final selections = <SettingsSection>[];

      try {
        // When the settings index is rendered.
        await tester.pumpWidget(
          _buildScreen(SettingScreen(onSectionSelected: selections.add)),
        );
        await tester.pump();

        // Then its localized title and ordered groups match the skeleton.
        final context = tester.element(find.byType(SettingScreen));
        final l10n = AppLocalizations.of(context)!;
        expect(Localizations.localeOf(context), const Locale('zh'));
        expect(MaterialLocalizations.of(context), isNotNull);
        expect(find.widgetWithText(AppBar, l10n.settingsTitle), findsOneWidget);
        expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);

        final tiles = find.byType(ListTile);
        expect(tiles, findsNWidgets(6));
        for (final (index, (_, label)) in sections.indexed) {
          final tile = tiles.at(index);
          expect(
            find.descendant(of: tile, matching: find.text(label)),
            findsOneWidget,
          );
          expect(
            find.ancestor(of: tile, matching: find.byType(Tooltip)),
            findsOneWidget,
          );
        }
        expect(selections, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });

    for (final (section, label) in sections) {
      testWidgets('selecting $label reports only its section', (tester) async {
        // Given an index with a recording selection callback.
        final selections = <SettingsSection>[];

        try {
          await tester.pumpWidget(
            _buildScreen(SettingScreen(onSectionSelected: selections.add)),
          );
          await tester.pump();
          expect(selections, isEmpty);

          // When this group's actual tile is tapped.
          await tester.tap(find.widgetWithText(ListTile, label));
          await tester.pump();

          // Then exactly one callback identifies that group.
          expect(selections, [section]);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      });
    }
  });

  group('Settings subpages', () {
    testWidgets('advanced page has a matching app bar and empty content', (
      tester,
    ) async {
      // Given a localized settings subpage.
      try {
        // When the skeleton is rendered.
        await tester.pumpWidget(_buildScreen(const AdvancedSettingsScreen()));
        await tester.pump();

        // Then only its app bar title is present, with no settings content.
        final l10n = AppLocalizations.of(tester.element(find.byType(AppBar)))!;
        expect(
          find.widgetWithText(AppBar, l10n.settingsAdvanced),
          findsOneWidget,
        );
        expect(find.byType(ListTile), findsNothing);
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(
          scaffold.body,
          anyOf(
            isNull,
            isA<SizedBox>().having((body) => body.child, 'child', isNull),
          ),
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });

    testWidgets(
      'library page shows bookmark sync and search history retention',
      (tester) async {
        // Given the localized library settings page with actual content.
        try {
          // When the page is rendered.
          await tester.pumpWidget(_buildScreen(const LibrarySettingsScreen()));
          await tester.pump();

          // Then the two entries are visible.
          final context = tester.element(find.byType(LibrarySettingsScreen));
          final l10n = AppLocalizations.of(context)!;
          expect(
            find.widgetWithText(AppBar, l10n.settingsLibrary),
            findsOneWidget,
          );
          // SwitchListTile for bookmark sync + ListTile with DropdownButton for retention
          expect(find.byType(SwitchListTile), findsOneWidget);
          expect(find.byType(ListTile), findsOneWidget);
          // Use descendant of SwitchListTile to avoid matching section header.
          expect(
            find.descendant(
              of: find.byType(SwitchListTile),
              matching: find.text(l10n.libraryBookmarkSync),
            ),
            findsOneWidget,
          );
          // Use descendant of ListTile to avoid matching section header.
          expect(
            find.descendant(
              of: find.byType(ListTile),
              matching: find.text(l10n.librarySearchHistoryRetention),
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      },
    );

    testWidgets('appearance page shows theme, font size and eye comfort', (
      tester,
    ) async {
      // Given the localized appearance settings page.
      try {
        // When the page is rendered.
        await tester.pumpWidget(_buildScreen(const AppearanceSettingsScreen()));
        await tester.pump();

        // Then the three entries are visible.
        final context = tester.element(find.byType(AppearanceSettingsScreen));
        final l10n = AppLocalizations.of(context)!;
        expect(
          find.widgetWithText(AppBar, l10n.settingsAppearance),
          findsOneWidget,
        );
        expect(find.byType(ListTile), findsNWidgets(3));
        // Use descendant of ListTile to avoid matching section headers.
        expect(
          find.descendant(
            of: find.byType(ListTile).at(0),
            matching: find.text(l10n.appearanceTheme),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(ListTile).at(1),
            matching: find.text(l10n.appearanceFontSize),
          ),
          findsOneWidget,
        );
        // Use descendant of SwitchListTile to avoid matching section header.
        expect(
          find.descendant(
            of: find.byType(SwitchListTile),
            matching: find.text(l10n.appearanceEyeComfort),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });
  });
}

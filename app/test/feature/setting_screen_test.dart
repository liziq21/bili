import 'package:app/app_scaffold.dart';
import 'package:app/feature/setting/advanced_settings_screen.dart';
import 'package:app/feature/setting/appearance_settings_screen.dart';
import 'package:app/feature/setting/library_settings_screen.dart';
import 'package:app/feature/setting/setting_screen.dart';
import 'package:app/feature/video/danmaku/danmaku_settings_screen.dart';
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
    testWidgets('shows the settings title and exactly eight groups in order', (
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

        final tiles = find.byType(ListTile);
        expect(tiles, findsNWidgets(8));
        final orderedLabels = [
          l10n.settingsPlayer,
          l10n.settingsAppearance,
          l10n.settingsHistory,
          l10n.settingsLibrary,
          l10n.settingsNotifications,
          l10n.settingsAdvanced,
          l10n.settingsDiscovery,
          l10n.settingsChannel,
        ];
        for (final (index, label) in orderedLabels.indexed) {
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

          // When this group's actual tile is tapped. 界面语言是 zh，标签要用
          // l10n 取，不能用测试名里的英文名去匹配。
          final l10n = AppLocalizations.of(
            tester.element(find.byType(SettingScreen)),
          )!;
          final localizedLabel = switch (section) {
            SettingsSection.player => l10n.settingsPlayer,
            SettingsSection.appearance => l10n.settingsAppearance,
            SettingsSection.history => l10n.settingsHistory,
            SettingsSection.library => l10n.settingsLibrary,
            SettingsSection.advanced => l10n.settingsAdvanced,
            _ => label,
          };
          await tester.tap(find.widgetWithText(ListTile, localizedLabel));
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

    testWidgets('selecting Notifications reports only its section', (
      tester,
    ) async {
      // Given an index with a recording selection callback.
      final selections = <SettingsSection>[];

      try {
        await tester.pumpWidget(
          _buildScreen(SettingScreen(onSectionSelected: selections.add)),
        );
        await tester.pump();
        expect(selections, isEmpty);

        // When the notifications tile is tapped (label is localized).
        final l10n = AppLocalizations.of(
          tester.element(find.byType(SettingScreen)),
        )!;
        await tester.tap(
          find.widgetWithText(ListTile, l10n.settingsNotifications),
        );
        await tester.pump();

        // Then exactly one callback identifies that group.
        expect(selections, [SettingsSection.notifications]);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });

    testWidgets('selecting Channel reports only its section', (tester) async {
      // Given an index with a recording selection callback.
      final selections = <SettingsSection>[];

      try {
        await tester.pumpWidget(
          _buildScreen(SettingScreen(onSectionSelected: selections.add)),
        );
        await tester.pump();

        // When the channel tile is tapped (label is localized).
        final l10n = AppLocalizations.of(
          tester.element(find.byType(SettingScreen)),
        )!;
        await tester.tap(find.widgetWithText(ListTile, l10n.settingsChannel));
        await tester.pump();

        // Then exactly one callback identifies the channel group.
        expect(selections, [SettingsSection.channel]);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });
  });

  group('Settings subpages', () {
    testWidgets('advanced page lists the danmaku entry and the cache action', (
      tester,
    ) async {
      // Given a localized advanced settings page.
      try {
        // When it is rendered.
        await tester.pumpWidget(_buildScreen(const AdvancedSettingsScreen()));
        await tester.pump();

        // Then the app bar names the page and both actions are listed.
        final l10n = AppLocalizations.of(tester.element(find.byType(AppBar)))!;
        expect(
          find.widgetWithText(AppBar, l10n.settingsAdvanced),
          findsOneWidget,
        );
        expect(find.byType(ListTile), findsNWidgets(2));
        expect(
          find.widgetWithText(ListTile, l10n.danmakuSettingsTitle),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(ListTile, l10n.clearImageCache),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });

    testWidgets('advanced page opens the danmaku settings page', (
      tester,
    ) async {
      // Given the advanced page on screen.
      try {
        await tester.pumpWidget(_buildScreen(const AdvancedSettingsScreen()));
        await tester.pump();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(AdvancedSettingsScreen)),
        )!;

        // When the danmaku entry is tapped.
        await tester.tap(
          find.widgetWithText(ListTile, l10n.danmakuSettingsTitle),
        );
        await tester.pumpAndSettle();

        // Then the danmaku settings page is pushed on top.
        expect(find.byType(DanmakuSettingsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });

    testWidgets('advanced page reports a cleared image cache', (tester) async {
      // Given the advanced page on screen.
      try {
        await tester.pumpWidget(_buildScreen(const AdvancedSettingsScreen()));
        await tester.pump();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(AdvancedSettingsScreen)),
        )!;

        // When the cache action is tapped.
        await tester.tap(find.widgetWithText(ListTile, l10n.clearImageCache));
        await tester.pump();

        // Then the user is told the cache was cleared, and nothing throws.
        // （内存图片缓存由 TestImageCache 接管，计数断言没有意义，这里断言
        // 用户可见的结果。）
        expect(find.text(l10n.imageCacheCleared), findsOneWidget);
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
          // SwitchListTile for bookmark sync + ListTile with DropdownButton for retention.
          // SwitchListTile is a subtype of ListTile, so use descendant matchers to
          // distinguish them instead of bare find.byType(ListTile).
          expect(find.byType(SwitchListTile), findsOneWidget);
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

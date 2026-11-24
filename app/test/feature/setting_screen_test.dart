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

/// 索引页的 ListView 按需构建子项，默认 800×600 视口放不下四个展开的分组，
/// 靠后的分组不会进入 widget 树。放大视口让所有分组一次性建出来。
Future<void> _useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1000, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  // 每个分节的 zh 标签；分组导航改版后仍要保证 8 个分节都能被选中。
  const sectionLabels = <SettingsSection, String Function(AppLocalizations)>{
    SettingsSection.player: _settingsPlayer,
    SettingsSection.appearance: _settingsAppearance,
    SettingsSection.history: _settingsHistory,
    SettingsSection.library: _settingsLibrary,
    SettingsSection.notifications: _settingsNotifications,
    SettingsSection.discovery: _settingsDiscovery,
    SettingsSection.channel: _settingsChannel,
    SettingsSection.advanced: _settingsAdvanced,
  };

  group('SettingScreen', () {
    testWidgets('shows the title, four expandable groups and eight sections', (
      tester,
    ) async {
      // Given an index with a recording selection callback.
      final selections = <SettingsSection>[];

      try {
        await _useTallSurface(tester);
        // When the settings index is rendered.
        await tester.pumpWidget(
          _buildScreen(SettingScreen(onSectionSelected: selections.add)),
        );
        await tester.pump();

        // Then the localized title and four expandable groups are present.
        final context = tester.element(find.byType(SettingScreen));
        final l10n = AppLocalizations.of(context)!;
        expect(Localizations.localeOf(context), const Locale('zh'));
        expect(MaterialLocalizations.of(context), isNotNull);
        expect(find.widgetWithText(AppBar, l10n.settingsTitle), findsOneWidget);
        expect(find.byType(ExpansionTile), findsNWidgets(4));

        final groupTitles = [
          l10n.settingsGroupPlayback,
          l10n.settingsGroupLibrary,
          l10n.settingsGroupDiscovery,
          l10n.settingsGroupOther,
        ];
        for (final title in groupTitles) {
          expect(find.text(title), findsOneWidget);
        }

        // And every section is visible because each group starts expanded.
        for (final labelOf in sectionLabels.values) {
          expect(find.text(labelOf(l10n)), findsOneWidget);
        }
        expect(selections, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });

    testWidgets('wraps each section tile in a tooltip', (tester) async {
      // Given the rendered index.
      try {
        await tester.pumpWidget(
          _buildScreen(SettingScreen(onSectionSelected: (_) {})),
        );
        await tester.pump();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(SettingScreen)),
        )!;

        // When a section tile is located.
        final tile = find.widgetWithText(ListTile, l10n.settingsPlayer);

        // Then it is wrapped in a tooltip carrying the same label.
        expect(tile, findsOneWidget);
        expect(
          find.ancestor(of: tile, matching: find.byType(Tooltip)),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });

    testWidgets('collapses and re-expands a group when its header is tapped', (
      tester,
    ) async {
      // Given the rendered index with the playback group expanded.
      try {
        await _useTallSurface(tester);
        await tester.pumpWidget(
          _buildScreen(SettingScreen(onSectionSelected: (_) {})),
        );
        await tester.pump();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(SettingScreen)),
        )!;
        expect(find.text(l10n.settingsPlayer), findsOneWidget);

        // When the playback group header is tapped.
        await tester.tap(find.text(l10n.settingsGroupPlayback));
        await tester.pumpAndSettle();

        // Then its sections are gone but the other groups stay expanded.
        expect(find.text(l10n.settingsPlayer), findsNothing);
        expect(find.text(l10n.settingsAppearance), findsNothing);
        expect(find.text(l10n.settingsLibrary), findsOneWidget);

        // When the header is tapped again.
        await tester.tap(find.text(l10n.settingsGroupPlayback));
        await tester.pumpAndSettle();

        // Then the sections return.
        expect(find.text(l10n.settingsPlayer), findsOneWidget);
        expect(find.text(l10n.settingsAppearance), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });

    testWidgets(
      'keeps a collapsed group collapsed after it leaves the viewport',
      (tester) async {
        // Given a short viewport where the lazy ListView recycles off-screen rows.
        try {
          await tester.binding.setSurfaceSize(const Size(400, 200));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            _buildScreen(SettingScreen(onSectionSelected: (_) {})),
          );
          await tester.pumpAndSettle();
          final l10n = AppLocalizations.of(
            tester.element(find.byType(SettingScreen)),
          )!;

          // When the playback group is collapsed and scrolled out of the cache.
          await tester.tap(find.text(l10n.settingsGroupPlayback));
          await tester.pumpAndSettle();
          expect(find.text(l10n.settingsPlayer), findsNothing);
          await tester.drag(find.byType(ListView), const Offset(0, -800));
          await tester.pumpAndSettle();

          // And scrolled back to the top so the group is rebuilt.
          await tester.drag(find.byType(ListView), const Offset(0, 800));
          await tester.pumpAndSettle();

          // Then the collapsed state survived the rebuild.
          expect(find.text(l10n.settingsPlayer), findsNothing);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      },
    );

    for (final MapEntry(key: section, value: labelOf)
        in sectionLabels.entries) {
      testWidgets('selecting $section reports only its section', (
        tester,
      ) async {
        // Given an index with a recording selection callback.
        final selections = <SettingsSection>[];

        try {
          await _useTallSurface(tester);
          await tester.pumpWidget(
            _buildScreen(SettingScreen(onSectionSelected: selections.add)),
          );
          await tester.pump();
          expect(selections, isEmpty);

          // When this section's tile is tapped (the label is localized).
          final l10n = AppLocalizations.of(
            tester.element(find.byType(SettingScreen)),
          )!;
          await tester.tap(find.widgetWithText(ListTile, labelOf(l10n)));
          await tester.pump();

          // Then exactly one callback identifies that section.
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
          expect(
            find.descendant(
              of: find.byType(SwitchListTile),
              matching: find.text(l10n.libraryBookmarkSync),
            ),
            findsOneWidget,
          );
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

    testWidgets('appearance page shows theme and font size', (tester) async {
      // Given the localized appearance settings page.
      try {
        // When the page is rendered.
        await tester.pumpWidget(_buildScreen(const AppearanceSettingsScreen()));
        await tester.pump();

        // Then both entries are visible, and the no-op eye comfort switch is
        // gone (issue #611): the page must not expose a control that cannot
        // change anything.
        final context = tester.element(find.byType(AppearanceSettingsScreen));
        final l10n = AppLocalizations.of(context)!;
        expect(
          find.widgetWithText(AppBar, l10n.settingsAppearance),
          findsOneWidget,
        );
        expect(find.byType(ListTile), findsNWidgets(2));
        expect(find.byType(SwitchListTile), findsNothing);
        // Use descendant of ListTile to avoid matching anything else.
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
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });
  });
}

String _settingsPlayer(AppLocalizations l10n) => l10n.settingsPlayer;
String _settingsAppearance(AppLocalizations l10n) => l10n.settingsAppearance;
String _settingsHistory(AppLocalizations l10n) => l10n.settingsHistory;
String _settingsLibrary(AppLocalizations l10n) => l10n.settingsLibrary;
String _settingsNotifications(AppLocalizations l10n) =>
    l10n.settingsNotifications;
String _settingsDiscovery(AppLocalizations l10n) => l10n.settingsDiscovery;
String _settingsChannel(AppLocalizations l10n) => l10n.settingsChannel;
String _settingsAdvanced(AppLocalizations l10n) => l10n.settingsAdvanced;

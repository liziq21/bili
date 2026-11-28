import 'dart:convert';

import 'package:app/app_scaffold.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/home/home_config.dart';
import 'package:app/feature/home/home_config_editor_screen.dart';
import 'package:app/feature/setting/common_widgets/setting_tiles.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:app/providers/media_sources_provider.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:app/design/design.dart';

class _FakeMediaSource() extends MediaSource {
  @override
  String get id => 'test';

  @override
  String get name => 'Test source';
}

final _persistedJson = jsonEncode({
  'sources': {
    'test': {
      'tabs': [
        {'id': 'tab_a', 'label': 'Tab A', 'isVisible': true, 'sortOrder': 0},
        {'id': 'tab_b', 'label': 'Tab B', 'isVisible': true, 'sortOrder': 1},
      ],
      'mainTabId': 'tab_a',
    },
  },
  'gridColumnsPortrait': 2,
  'gridColumnsLandscape': 3,
});

Widget _buildScreen(PreferencesDataSource preferences) {
  return Provider<PreferencesDataSource>.value(
    value: preferences,
    child: Provider<MediaSourceCatalog>.value(
      value: MediaSourceCatalog([
        MediaSourceDefinition(
          id: 'test',
          name: 'Test source',
          create: () => _FakeMediaSource(),
        ),
      ]),
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AppScaffold(child: HomeConfigEditorScreen()),
      ),
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

  Future<HomeConfig> persistedConfig() async {
    final raw = await preferences.get(PreferencesKey.homeConfig);
    if (raw case Success(:final success)) {
      return HomeConfig.fromJsonOrDefault(jsonDecode(success));
    }
    throw StateError('home config persisted as error');
  }

  testWidgets('renders persisted tabs', (tester) async {
    await preferences.set(PreferencesKey.homeConfig, _persistedJson);
    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Tab A'), findsOneWidget);
    expect(find.text('Tab B'), findsOneWidget);
  });

  testWidgets('titles the page like the settings entry that opens it', (
    tester,
  ) async {
    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(HomeConfigEditorScreen));
    final l10n = AppLocalizations.of(context)!;

    expect(find.widgetWithText(AppBar, l10n.homeConfigTitle), findsOneWidget);
    expect(l10n.homeConfigTitle, l10n.settingsDiscovery);
  });

  testWidgets('shows an empty state instead of a bare tabs header', (
    tester,
  ) async {
    await preferences.set(
      PreferencesKey.homeConfig,
      jsonEncode({
        'sources': {
          'test': {'tabs': <Object>[], 'mainTabId': null},
        },
        'gridColumnsPortrait': 2,
        'gridColumnsLandscape': 2,
      }),
    );
    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(HomeConfigEditorScreen));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text(l10n.homeConfigNoTabs), findsOneWidget);
    expect(find.text(l10n.homeConfigTabs), findsNothing);
  });

  testWidgets('toggles tab visibility and persists', (tester) async {
    await preferences.set(PreferencesKey.homeConfig, _persistedJson);
    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(2));
    await tester.tap(switches.at(0));
    await tester.pump();

    final config = await persistedConfig();
    expect(config.sources['test']!.tabs[0].isVisible, isFalse);
    expect(config.sources['test']!.tabs[1].isVisible, isTrue);
  });

  testWidgets('moves tab up and persists order', (tester) async {
    await preferences.set(PreferencesKey.homeConfig, _persistedJson);
    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(AppIcons.moveUp).at(1));
    await tester.pump();

    final config = await persistedConfig();
    expect(config.sources['test']!.tabs[0].sortOrder, equals(1));
    expect(config.sources['test']!.tabs[1].sortOrder, equals(0));
  });

  testWidgets('sets main tab and persists', (tester) async {
    await preferences.set(PreferencesKey.homeConfig, _persistedJson);
    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(AppIcons.mainSection));
    await tester.pump();

    final config = await persistedConfig();
    expect(config.sources['test']!.mainTabId, equals('tab_b'));
  });

  testWidgets('marks the current main tab with a filled accent pin', (
    tester,
  ) async {
    await preferences.set(PreferencesKey.homeConfig, _persistedJson);
    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(HomeConfigEditorScreen));
    final l10n = AppLocalizations.of(context)!;

    // Tab A is the main tab: filled pin, accent colour, explicit state label.
    expect(find.byIcon(AppIcons.mainSectionSelected), findsOneWidget);
    expect(find.byIcon(AppIcons.mainSection), findsOneWidget);
    final mainPin = tester.widget<Icon>(
      find.byIcon(AppIcons.mainSectionSelected),
    );
    expect(mainPin.color, $styles.colors.accentFill);
    expect(find.text(l10n.homeConfigMainTab), findsOneWidget);
    expect(find.text(l10n.homeConfigSetMain), findsNothing);
  });

  testWidgets('edits grid columns and persists', (tester) async {
    await preferences.set(PreferencesKey.homeConfig, _persistedJson);
    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final pickers = find.byType(SettingValueTile);
    expect(pickers, findsNWidgets(2));
    await tester.tap(pickers.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SettingPickerOption, '4'));
    await tester.pumpAndSettle();

    final config = await persistedConfig();
    expect(config.gridColumnsPortrait, equals(4));
    expect(config.gridColumnsLandscape, equals(3));
  });

  Future<void> pumpEditor(WidgetTester tester) async {
    await preferences.set(PreferencesKey.homeConfig, _persistedJson);
    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  SemanticsNode nodeLabelled(WidgetTester tester, String label) =>
      tester.getSemantics(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == label,
        ),
      );

  testWidgets('activates the set-main button from the screen-reader tap', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpEditor(tester);

    final node = nodeLabelled(tester, '设为主标签: Tab B');
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pump();

    final config = await persistedConfig();
    expect(config.sources['test']!.mainTabId, equals('tab_b'));
    semantics.dispose();
  });

  testWidgets('activates the move-up button from the screen-reader tap', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpEditor(tester);

    final moveUp = nodeLabelled(tester, '上移: Tab B');
    expect(moveUp.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    moveUp.owner!.performAction(moveUp.id, SemanticsAction.tap);
    await tester.pump();

    final reordered = await persistedConfig();
    expect(reordered.sources['test']!.tabs[0].sortOrder, equals(1));
    expect(reordered.sources['test']!.tabs[1].sortOrder, equals(0));
    semantics.dispose();
  });

  testWidgets('activates the move-down button from the screen-reader tap', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpEditor(tester);

    final moveDown = nodeLabelled(tester, '下移: Tab A');
    expect(moveDown.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    moveDown.owner!.performAction(moveDown.id, SemanticsAction.tap);
    await tester.pump();

    final reordered = await persistedConfig();
    expect(reordered.sources['test']!.tabs[0].sortOrder, equals(1));
    expect(reordered.sources['test']!.tabs[1].sortOrder, equals(0));
    semantics.dispose();
  });

  testWidgets('keeps a moved tab row alive so screen-reader focus follows it', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpEditor(tester);

    final row = find.byKey(const ValueKey('test-tab_b'));
    final before = tester.element(row);

    final moveUp = nodeLabelled(tester, '上移: Tab B');
    moveUp.owner!.performAction(moveUp.id, SemanticsAction.tap);
    await tester.pump();

    // The same Element survives the reorder, so the row's semantics node is not
    // torn down and rebuilt under a different tab.
    expect(
      tester.element(find.byKey(const ValueKey('test-tab_b'))),
      same(before),
    );
    semantics.dispose();
  });

  testWidgets('exposes no tap action for disabled tab buttons', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpEditor(tester);

    for (final label in ['当前主标签: Tab A', '上移: Tab A', '下移: Tab B']) {
      final node = nodeLabelled(tester, label);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
        reason: label,
      );
    }
    semantics.dispose();
  });

  testWidgets('opens the column picker from the screen-reader tap', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpEditor(tester);

    final portraitTile = find.byType(SettingValueTile).at(0);
    final node = tester.getSemantics(
      find.descendant(of: portraitTile, matching: find.byType(ListTile)),
    );
    final data = node.getSemanticsData();
    expect(data.label, contains('竖屏'));
    expect(data.label, contains('2'));
    expect(data.hasAction(SemanticsAction.tap), isTrue);

    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SettingPickerOption, '4'));
    await tester.pumpAndSettle();

    final config = await persistedConfig();
    expect(config.gridColumnsPortrait, equals(4));
    semantics.dispose();
  });

  testWidgets('exposes accessible semantics for screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await preferences.set(PreferencesKey.homeConfig, _persistedJson);
    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Each column row exposes its orientation and current value with a tap
    // action.
    for (final (index, label, value) in [(0, '竖屏', '2'), (1, '横屏', '3')]) {
      final data = tester
          .getSemantics(
            find.descendant(
              of: find.byType(SettingValueTile).at(index),
              matching: find.byType(ListTile),
            ),
          )
          .getSemanticsData();
      expect(data.label, contains(label));
      expect(data.label, contains(value));
      expect(data.hasAction(SemanticsAction.tap), isTrue);
    }

    // Tab visibility switches with state semantics
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Tab A 显示',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Tab B 显示',
      ),
      findsOneWidget,
    );

    // Tab action buttons with contextual tab labels
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == '当前主标签: Tab A' &&
            w.properties.enabled == false &&
            w.excludeSemantics == true,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == '设为主标签: Tab B' &&
            w.properties.enabled == true &&
            w.excludeSemantics == true,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == '上移: Tab A' &&
            w.properties.enabled == false &&
            w.excludeSemantics == true,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == '上移: Tab B' &&
            w.properties.enabled == true &&
            w.excludeSemantics == true,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == '下移: Tab A' &&
            w.properties.enabled == true &&
            w.excludeSemantics == true,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == '下移: Tab B' &&
            w.properties.enabled == false &&
            w.excludeSemantics == true,
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });
}

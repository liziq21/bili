import 'dart:convert';

import 'package:app/app_scaffold.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/home/home_config.dart';
import 'package:app/feature/home/home_config_editor_screen.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:app/providers/media_sources_provider.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _FakeMediaSource extends MediaSource {
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

  Future<HomeConfig> _persistedConfig() async {
    final raw = await preferences.get(PreferencesKey.homeConfig);
    if (raw case Ok(:final value)) {
      return HomeConfig.fromJsonOrDefault(jsonDecode(value));
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

  testWidgets('toggles tab visibility and persists', (tester) async {
    await preferences.set(PreferencesKey.homeConfig, _persistedJson);
    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(2));
    await tester.tap(switches.at(0));
    await tester.pump();

    final config = await _persistedConfig();
    expect(config.sources['test']!.tabs[0].isVisible, isFalse);
    expect(config.sources['test']!.tabs[1].isVisible, isTrue);
  });

  testWidgets('moves tab up and persists order', (tester) async {
    await preferences.set(PreferencesKey.homeConfig, _persistedJson);
    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.arrow_upward).at(1));
    await tester.pump();

    final config = await _persistedConfig();
    expect(config.sources['test']!.tabs[0].sortOrder, equals(1));
    expect(config.sources['test']!.tabs[1].sortOrder, equals(0));
  });

  testWidgets('sets main tab and persists', (tester) async {
    await preferences.set(PreferencesKey.homeConfig, _persistedJson);
    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pump();

    final config = await _persistedConfig();
    expect(config.sources['test']!.mainTabId, equals('tab_b'));
  });

  testWidgets('edits grid columns and persists', (tester) async {
    await preferences.set(PreferencesKey.homeConfig, _persistedJson);
    await tester.pumpWidget(_buildScreen(preferences));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final dropdowns = find.byType(DropdownButton<int>);
    expect(dropdowns, findsNWidgets(2));
    await tester.tap(dropdowns.at(0));
    await tester.pump();
    await tester.tap(find.text('3').last);
    await tester.pump();

    final config = await _persistedConfig();
    expect(config.gridColumnsPortrait, equals(3));
    expect(config.gridColumnsLandscape, equals(3));
  });
}

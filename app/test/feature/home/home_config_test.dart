import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/home/home_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesDataSource preferences;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = PreferencesDataSource(
      sharedPreferences: SharedPreferencesAsync(),
    );
  });

  tearDown(() {
    preferences.dispose();
  });

  test('defaults cover the currently available home feeds', () {
    final config = HomeConfig.defaults();
    final bilibili = config.sources['bilibili'];

    expect(bilibili, isNotNull);
    expect(bilibili!.tabs.map((tab) => tab.id), ['popular', 'ranking', 'live']);
    expect(bilibili.mainTabId, 'popular');
    expect(config.sources['youtube']!.tabs, isEmpty);
    expect(config.gridColumnsPortrait, 2);
    expect(config.gridColumnsLandscape, 2);
  });

  test('round-trips a configured home model through JSON', () {
    final original = HomeConfig(
      {
        'bilibili': HomeSourceConfig([
          const HomeTabConfig(
            id: 'ranking',
            label: 'ranking',
            isVisible: false,
            sortOrder: 3,
          ),
        ], mainTabId: 'ranking'),
      },
      gridColumnsPortrait: 1,
      gridColumnsLandscape: 4,
    );

    final restored = HomeConfig.fromJson(original.toJson());

    expect(restored, original);
  });

  test('falls back to defaults for malformed JSON data', () {
    final fallback = HomeConfig.fromJsonOrDefault({
      'sources': {'bilibili': 'not-an-object'},
      'gridColumnsPortrait': 0,
      'gridColumnsLandscape': 2,
    });

    expect(fallback, HomeConfig.defaults());
  });

  test('saves and loads the configuration through preferences', () async {
    final original = HomeConfig(
      {
        'bilibili': HomeSourceConfig(const [
          HomeTabConfig(id: 'popular', label: 'popular'),
        ], mainTabId: 'popular'),
      },
      gridColumnsPortrait: 2,
      gridColumnsLandscape: 3,
    );

    final result = await original.save(preferences);
    final restored = await HomeConfig.load(preferences);

    expect(result.isOk, isTrue);
    expect(restored, original);
  });

  test('loads defaults when the persisted JSON is invalid', () async {
    await preferences.set(PreferencesKey.homeConfig, '{invalid-json');

    final restored = await HomeConfig.load(preferences);

    expect(restored, HomeConfig.defaults());
  });
}

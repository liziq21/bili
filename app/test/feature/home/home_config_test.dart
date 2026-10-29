import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/home/home_config.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class _FakeVideoFeed(
  @override final String id,
  @override final String title,
) extends VideoFeedRemoteDataSource {
  @override
  String get sourceId => 'bilibili';

  @override
  Future<Result<Page<VideoModel>>> fetchFeed({int? pageKey}) =>
      throw UnimplementedError();
}

final class _FakeLiveFeed(
  @override final String id,
  @override final String title,
) extends LiveRoomFeedRemoteDataSource {
  @override
  String get sourceId => 'bilibili';

  @override
  Future<Result<Page<LiveRoomModel>>> fetchFeed({int? pageKey}) =>
      throw UnimplementedError();
}

final class _FakeSource(
  @override final String id,
  @override final String name, {
  final List<VideoFeedRemoteDataSource> videoFeeds = const [],
  final List<LiveRoomFeedRemoteDataSource> liveFeeds = const [],
}) extends MediaSource {
  @override
  List<VideoFeedRemoteDataSource> get videoFeedDataSources => videoFeeds;

  @override
  List<LiveRoomFeedRemoteDataSource> get liveRoomFeedDataSources => liveFeeds;
}

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
    final config = HomeConfig.defaults(
      sources: [
        _FakeSource(
          'bilibili',
          'Bilibili',
          videoFeeds: [
            _FakeVideoFeed('popular', '热门视频'),
            _FakeVideoFeed('ranking', '排行榜'),
          ],
          liveFeeds: [_FakeLiveFeed('live', '直播')],
        ),
        _FakeSource('youtube', 'YouTube'),
      ],
    );
    final bilibili = config.sources['bilibili'];

    expect(bilibili, isNotNull);
    expect(bilibili!.tabs.map((tab) => tab.id), ['popular', 'ranking', 'live']);
    expect(bilibili.tabs.map((tab) => tab.label), ['热门视频', '排行榜', '直播']);
    expect(bilibili.mainTabId, 'popular');
    expect(config.sources['youtube']!.tabs, isEmpty);
    expect(config.gridColumnsPortrait, 2);
    expect(config.gridColumnsLandscape, 2);
  });

  test('defaults keep video and live feeds with the same id distinct', () {
    final config = HomeConfig.defaults(
      sources: [
        _FakeSource(
          'bilibili',
          'Bilibili',
          videoFeeds: [_FakeVideoFeed('shared', '视频')],
          liveFeeds: [_FakeLiveFeed('shared', '直播')],
        ),
      ],
    );

    expect(config.sources['bilibili']!.tabs.map((tab) => tab.id), [
      'shared',
      'shared:live',
    ]);
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

    final restored = await HomeConfig.load(
      preferences,
      sources: [
        _FakeSource(
          'bilibili',
          'Bilibili',
          videoFeeds: [_FakeVideoFeed('popular', '热门视频')],
        ),
      ],
    );

    expect(restored.sources['bilibili']!.tabs.single.label, '热门视频');
  });

  group('HomeConfigEditorX', () {
    HomeConfig _baseConfig() {
      return HomeConfig(
        {
          'test': HomeSourceConfig([
            HomeTabConfig(
              id: 'tab_a',
              label: 'Tab A',
              isVisible: true,
              sortOrder: 0,
            ),
            HomeTabConfig(
              id: 'tab_b',
              label: 'Tab B',
              isVisible: true,
              sortOrder: 1,
            ),
          ], mainTabId: 'tab_a'),
        },
        gridColumnsPortrait: 2,
        gridColumnsLandscape: 3,
      );
    }

    test('toggles tab visibility', () {
      final updated = _baseConfig().withTabVisible('test', 'tab_a', false);
      expect(updated.sources['test']!.tabs[0].isVisible, isFalse);
      expect(updated.sources['test']!.tabs[1].isVisible, isTrue);
    });

    test('moves tab up and swaps sort order', () {
      final updated = _baseConfig().withTabMoved('test', 'tab_b', true);
      expect(updated.sources['test']!.tabs[0].sortOrder, equals(1));
      expect(updated.sources['test']!.tabs[1].sortOrder, equals(0));
    });

    test('sets main tab', () {
      final updated = _baseConfig().withMainTab('test', 'tab_b');
      expect(updated.sources['test']!.mainTabId, equals('tab_b'));
    });

    test('edits grid columns', () {
      final updated = _baseConfig().withGridColumns(portrait: 4, landscape: 5);
      expect(updated.gridColumnsPortrait, equals(4));
      expect(updated.gridColumnsLandscape, equals(5));
    });
  });
}

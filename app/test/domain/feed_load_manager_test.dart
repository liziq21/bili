import 'package:app/data/repository/feed_repository.dart';
import 'package:app/database/app_database.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/domain/feed_load_manager.dart';
import 'package:app/feature/notification/feed_update_notifier.dart';
import 'package:data/data.dart' hide Page;
import 'package:data/data.dart' as data show Page;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// 记录每次通知调用的参数，并按预设返回基线。
final class _RecordingNotifier({final Result<int, Exception>? result})
    implements FeedUpdateNotifier {
  final calls = <({int currentCount, int threshold, int lastNotifiedCount})>[];

  @override
  bool get isSupported => true;

  @override
  Stream<void> get feedOpened => const Stream.empty();

  @override
  Future<Result<void, Exception>> initialize() async =>
      const Result.success(null);

  @override
  Future<Result<bool, Exception>> requestPermission() async =>
      const Result.success(true);

  @override
  Future<Result<int, Exception>> notifyIfThresholdReached({
    required int currentCount,
    required int threshold,
    required int lastNotifiedCount,
  }) async {
    calls.add((
      currentCount: currentCount,
      threshold: threshold,
      lastNotifiedCount: lastNotifiedCount,
    ));
    return result ??
        Result.success(
          currentCount - lastNotifiedCount >= threshold
              ? currentCount
              : lastNotifiedCount,
        );
  }

  @override
  Future<void> dispose() async {}
}

final class _FakeUserVideosDataSource({
  required final Map<String, List<List<String>>> pagesByChannel,
}) implements UserVideosRemoteDataSource {
  int requestCount = 0;

  @override
  String get sourceId => 'bilibili';

  @override
  Future<Result<data.Page<VideoModel>, Exception>> fetchUserVideos({
    required String channelId,
    int page = 1,
    int pageSize = 30,
  }) async {
    requestCount++;
    final pages = pagesByChannel[channelId] ?? const [];
    if (page < 1 || page > pages.length) {
      return Result.error(Exception('page $page out of range'));
    }
    return Result.success(
      data.Page<VideoModel>(
        number: page,
        totalPages: pages.length,
        data: [
          for (final id in pages[page - 1])
            VideoModel(id: id, title: id, url: 'https://example.test/$id'),
        ],
      ),
    );
  }
}

void main() {
  late AppDatabase db;
  late PreferencesDataSource preferences;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = PreferencesDataSource(
      sharedPreferences: SharedPreferencesAsync(),
    );
  });

  tearDown(() async {
    preferences.dispose();
    await db.close();
  });

  Future<void> subscribe(String channelId) =>
      db.localLibraryDao.saveSubscription(
        LocalSubscriptionCompanion.insert(
          sourceId: 'bilibili',
          originalId: channelId,
          name: channelId,
        ),
      );

  FeedLoadManager buildManager(
    UserVideosRemoteDataSource remote,
    FeedUpdateNotifier notifier,
  ) => FeedLoadManager(
    repository: FeedRepository(
      feedDao: db.feedDao,
      libraryDao: db.localLibraryDao,
      remoteDataSource: remote,
    ),
    notifier: notifier,
    preferences: preferences,
  );

  test('coalesces concurrent loads into a single remote pass', () async {
    // Given one subscription and two triggers fired together.
    await subscribe('creator-1');
    final remote = _FakeUserVideosDataSource(
      pagesByChannel: {
        'creator-1': [
          ['v1'],
        ],
      },
    );
    final manager = buildManager(remote, _RecordingNotifier());

    // When both loads start before the first finishes.
    final results = await Future.wait([
      manager.load(sourceId: 'bilibili'),
      manager.load(sourceId: 'bilibili'),
    ]);

    // Then the same work is shared instead of duplicated.
    expect(remote.requestCount, 1);
    expect(results.map((result) => result.newEntryCount), [1, 1]);
  });

  test('notifies with the unread count and the stored threshold', () async {
    // Given a threshold of 2 and three fresh entries.
    await preferences.set(PreferencesKey.feedUpdateNotificationThreshold, 2);
    await subscribe('creator-1');
    final notifier = _RecordingNotifier();
    final manager = buildManager(
      _FakeUserVideosDataSource(
        pagesByChannel: {
          'creator-1': [
            ['v1', 'v2', 'v3'],
          ],
        },
      ),
      notifier,
    );

    // When the feed loads.
    await manager.load(sourceId: 'bilibili');

    // Then the notifier sees the unread total and the persisted threshold.
    expect(notifier.calls, hasLength(1));
    expect(notifier.calls.single.currentCount, 3);
    expect(notifier.calls.single.threshold, 2);
    expect(notifier.calls.single.lastNotifiedCount, 0);
    expect(
      await preferences.get(PreferencesKey.feedUpdateNotificationLastCount),
      isA<Success<int, Exception>>(),
    );
  });

  test('lowers the baseline when unread count falls back', () async {
    // Given a baseline above the current unread count.
    await preferences.set(PreferencesKey.feedUpdateNotificationLastCount, 10);
    await subscribe('creator-1');
    final manager = buildManager(
      _FakeUserVideosDataSource(
        pagesByChannel: {
          'creator-1': [
            ['v1'],
          ],
        },
      ),
      _RecordingNotifier(),
    );

    // When the feed reloads with only one unread entry.
    await manager.load(sourceId: 'bilibili');

    // Then the baseline drops so future growth can notify again.
    final stored = await preferences.get(
      PreferencesKey.feedUpdateNotificationLastCount,
    );
    expect((stored as Success<int, Exception>).success, 1);
  });

  test('keeps loading results when the notifier fails', () async {
    // Given a notifier that reports an error.
    await subscribe('creator-1');
    final manager = buildManager(
      _FakeUserVideosDataSource(
        pagesByChannel: {
          'creator-1': [
            ['v1', 'v2'],
          ],
        },
      ),
      _RecordingNotifier(result: Result.error(Exception('no permission'))),
    );

    // When the feed loads.
    final result = await manager.load(sourceId: 'bilibili');

    // Then the entries are still reported as loaded.
    expect(result.newEntryCount, 2);
    expect(result.unreadCount, 2);
  });

  test('loads nothing when the source lacks channel support', () async {
    // Given a manager whose repository has no remote capability.
    final notifier = _RecordingNotifier();
    final manager = FeedLoadManager(
      repository: FeedRepository(
        feedDao: db.feedDao,
        libraryDao: db.localLibraryDao,
      ),
      notifier: notifier,
      preferences: preferences,
    );

    // When it loads.
    final result = await manager.load(sourceId: 'bilibili');

    // Then nothing is stored and no notification is attempted.
    expect(result.newEntryCount, 0);
    expect(await db.feedDao.getEntries(sourceId: 'bilibili'), isEmpty);
    expect(notifier.calls.single.currentCount, 0);
  });
}

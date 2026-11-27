import 'package:app/data/repository/feed_repository.dart';
import 'package:app/database/app_database.dart';
import 'package:app/database/table/local_library.dart';
import 'package:app/domain/feed_load_manager.dart';
import 'package:app/feature/feed/feed_cubit.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late FeedCubit cubit;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    cubit = FeedCubit(
      feedDao: db.feedDao,
      libraryDao: db.localLibraryDao,
      sourceId: 'bilibili',
    );
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  Future<void> addSubscription(String channelId, String name) =>
      db.localLibraryDao.saveSubscription(
        LocalSubscriptionCompanion.insert(
          sourceId: 'bilibili',
          originalId: channelId,
          name: name,
        ),
      );

  Future<void> addEntry(
    String channelId,
    String entryId, {
    required DateTime publishedAt,
    bool isRead = false,
    String? creatorProfileName,
  }) => db.feedDao.upsertEntries([
    FeedEntryCompanion.insert(
      sourceId: 'bilibili',
      channelId: channelId,
      entryId: entryId,
      entryType: FeedEntry.typeVideo,
      title: 'Entry $entryId',
      url: 'https://example.com/$entryId',
      creatorProfileName: Value(creatorProfileName),
      publishedAt: Value(publishedAt),
      isRead: Value(isRead),
    ),
  ]);

  /// Drift 的查询流在真实异步 I/O 上跑，且每次写入都会推一帧。等第一帧
  /// 「不 loading」不够——那时后面几次写入可能还没落库，所以每个用例都等到
  /// 自己关心的那个状态出现。
  Future<void> waitFor(
    bool Function(FeedState state) predicate, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (predicate(cubit.state)) return;
    await cubit.stream.firstWhere(predicate).timeout(timeout);
  }

  test('pulls an incremental load when the feed cubit is created', () async {
    final manager = _RecordingFeedLoadManager();
    final feedCubit = FeedCubit(
      feedDao: db.feedDao,
      libraryDao: db.localLibraryDao,
      sourceId: 'bilibili',
      feedLoadManager: manager,
    );
    addTearDown(feedCubit.close);

    await pumpEventQueue();

    expect(manager.loadedSourceIds, ['bilibili']);
  });

  test('groups entries by channel and counts unread per channel', () async {
    await addSubscription('c1', 'Channel One');
    await addSubscription('c2', 'Channel Two');
    await addEntry('c1', 'v1', publishedAt: DateTime(2026, 5, 2));
    await addEntry('c1', 'v2', publishedAt: DateTime(2026, 5, 1), isRead: true);
    await addEntry('c2', 'v3', publishedAt: DateTime(2026, 5, 3));

    await waitFor((state) => state.groups.length == 2);

    final groups = cubit.state.groups;
    expect(groups.map((group) => group.channelId), ['c2', 'c1']);
    expect(groups.map((group) => group.channelName), [
      'Channel Two',
      'Channel One',
    ]);
    expect(groups[1].entries.map((entry) => entry.entryId), ['v1', 'v2']);
    expect(groups[1].unreadCount, 1);
    expect(groups[0].unreadCount, 1);
    expect(cubit.state.unreadCount, 2);
  });

  test('falls back to the entry creator name after unsubscribing', () async {
    await addEntry(
      'c1',
      'v1',
      publishedAt: DateTime(2026, 5, 1),
      creatorProfileName: 'Kept Name',
    );
    await waitFor((state) => state.groups.isNotEmpty);

    expect(cubit.state.groups.single.channelName, 'Kept Name');
  });

  test(
    'all channels start expanded and toggle flips only the target',
    () async {
      await addSubscription('c1', 'One');
      await addSubscription('c2', 'Two');
      await addEntry('c1', 'v1', publishedAt: DateTime(2026, 5, 1));
      await addEntry('c2', 'v2', publishedAt: DateTime(2026, 5, 2));
      await waitFor((state) => state.groups.length == 2);

      expect(cubit.state.isExpanded('c1'), isTrue);
      expect(cubit.state.isExpanded('c2'), isTrue);

      cubit.toggleChannel('c1');
      expect(cubit.state.isExpanded('c1'), isFalse);
      expect(cubit.state.isExpanded('c2'), isTrue);

      cubit.toggleChannel('c1');
      expect(cubit.state.isExpanded('c1'), isTrue);
    },
  );

  test('marking a channel read keeps the collapse state', () async {
    await addSubscription('c1', 'One');
    await addEntry('c1', 'v1', publishedAt: DateTime(2026, 5, 1));
    await waitFor((state) => state.groups.isNotEmpty);
    cubit.toggleChannel('c1');

    final updated = waitFor(
      (state) => state.groups.singleOrNull?.unreadCount == 0,
    );
    await cubit.markChannelRead('c1');
    await updated;

    expect(cubit.state.isExpanded('c1'), isFalse);
  });

  test('emits an empty state when nothing is stored', () async {
    await waitFor((state) => !state.isLoading);

    expect(cubit.state.groups, isEmpty);
    expect(cubit.state.isEmpty, isTrue);
    expect(cubit.state.hasError, isFalse);
  });
}

final class _RecordingFeedLoadManager() implements FeedLoadManager {
  final loadedSourceIds = <String>[];

  @override
  Future<FeedLoadResult> load({required String sourceId}) async {
    loadedSourceIds.add(sourceId);
    return const FeedLoadResult();
  }
}

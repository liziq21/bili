import 'package:app/database/app_database.dart';
import 'package:app/database/dao/feed_dao.dart';
import 'package:app/database/table/local_library.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  group(FeedDao, () {
    late AppDatabase db;
    late FeedDao dao;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dao = db.feedDao;
    });

    tearDown(() => db.close());

    test('upserts metadata without resetting the read marker', () async {
      final publishedAt = DateTime.utc(2026, 10, 30);
      await dao.upsertEntries([
        _entry(entryId: 'video-1', title: 'Original', publishedAt: publishedAt),
      ]);
      await dao.markAsRead('bilibili', 'creator-1', 'video-1');

      await dao.upsertEntries([
        _entry(
          entryId: 'video-1',
          title: 'Updated',
          publishedAt: publishedAt,
          thumbnailUrl: 'https://img.test/updated.jpg',
        ),
      ]);

      final entries = await dao.getEntries(sourceId: 'bilibili');
      expect(entries, hasLength(1));
      expect(entries.single.title, 'Updated');
      expect(entries.single.thumbnailUrl, 'https://img.test/updated.jpg');
      expect(entries.single.isRead, isTrue);
    });

    test(
      'filters by channel and unread state without crossing sources',
      () async {
        await dao.upsertEntries([
          _entry(entryId: 'a-1', channelId: 'creator-1'),
          _entry(entryId: 'a-2', channelId: 'creator-1'),
          _entry(entryId: 'b-1', channelId: 'creator-2'),
          _entry(
            entryId: 'other-1',
            sourceId: 'youtube',
            channelId: 'creator-1',
          ),
        ]);
        await dao.markAsRead('bilibili', 'creator-1', 'a-1');

        expect(
          (await dao.getEntries(
            sourceId: 'bilibili',
            channelId: 'creator-1',
          )).map((entry) => entry.entryId),
          ['a-2', 'a-1'],
        );
        expect(
          (await dao.getEntries(
            sourceId: 'bilibili',
            channelId: 'creator-1',
            unreadOnly: true,
          )).map((entry) => entry.entryId),
          ['a-2'],
        );
        expect(await dao.getUnreadCount('bilibili', 'creator-1'), 1);
        expect(await dao.getUnreadCount('youtube', 'creator-1'), 1);

        await dao.markAllRead('bilibili', 'creator-1');
        expect(await dao.getUnreadCount('bilibili', 'creator-1'), 0);
      },
    );

    test('deletes only expired entries in the requested channel', () async {
      final now = DateTime.now();
      await dao.upsertEntries([
        _entry(
          entryId: 'expired',
          channelId: 'creator-1',
          publishedAt: now.subtract(const Duration(days: 31)),
        ),
        _entry(
          entryId: 'recent',
          channelId: 'creator-1',
          publishedAt: now.subtract(const Duration(days: 1)),
        ),
        _entry(
          entryId: 'other-channel',
          channelId: 'creator-2',
          publishedAt: now.subtract(const Duration(days: 31)),
        ),
        _entry(
          entryId: 'other-source',
          sourceId: 'youtube',
          channelId: 'creator-1',
          publishedAt: now.subtract(const Duration(days: 31)),
        ),
        _entry(entryId: 'unknown-date', channelId: 'creator-1'),
      ]);

      await dao.deleteOldEntries('bilibili', 'creator-1');

      expect(
        (await dao.getEntries(sourceId: 'bilibili'))
            .map((entry) => entry.entryId),
        ['recent', 'other-channel', 'unknown-date'],
      );
      expect(await dao.getEntries(sourceId: 'youtube'), hasLength(1));
    });

    test('rejects blank identities and unsupported entry types', () async {
      await expectLater(
        dao.upsertEntries([_entry(entryId: 'blank-channel', channelId: '   ')]),
        throwsArgumentError,
      );
      await expectLater(
        dao.upsertEntries([_entry(entryId: 'bad-type', entryType: 'comment')]),
        throwsArgumentError,
      );
      expect(await dao.getEntries(sourceId: 'bilibili'), isEmpty);
    });
  });
}

FeedEntryCompanion _entry({
  String sourceId = 'bilibili',
  String channelId = 'creator-1',
  required String entryId,
  String entryType = FeedEntry.typeVideo,
  String? title,
  String? thumbnailUrl,
  DateTime? publishedAt,
}) => FeedEntryCompanion.insert(
  sourceId: sourceId,
  channelId: channelId,
  entryId: entryId,
  entryType: entryType,
  title: title ?? entryId,
  url: 'https://example.test/$entryId',
  thumbnailUrl: Value(thumbnailUrl),
  publishedAt: Value(publishedAt),
);

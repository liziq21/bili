import 'package:app/database/app_database.dart';
import 'package:app/database/dao/local_library_dao.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late LocalLibraryDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.localLibraryDao;
  });

  tearDown(() => db.close());

  test('upserts by source and original id and removes idempotently', () async {
    await dao.saveBookmark(_bookmark('source-a', 'same-id', 'A'));
    await dao.saveBookmark(_bookmark('source-b', 'same-id', 'B'));
    await dao.saveBookmark(_bookmark('source-a', 'same-id', 'A updated'));

    final bookmarks = await dao.getBookmarks();
    expect(bookmarks, hasLength(2));
    expect(
      bookmarks
          .singleWhere((bookmark) => bookmark.sourceId == 'source-a')
          .title,
      'A updated',
    );

    await dao.removeBookmark('source-a', 'same-id');
    await dao.removeBookmark('source-a', 'same-id');

    expect(await dao.isBookmarked('source-a', 'same-id'), isFalse);
    expect(await dao.isBookmarked('source-b', 'same-id'), isTrue);
  });

  test(
    'keeps duplicate playlist entries distinct and positions dense',
    () async {
      final playlistId = await dao.createPlaylist('source-a', 'Queue');
      await dao.addPlaylistItem(
        playlistId: playlistId,
        item: _playlistItem(playlistId, 'source-a', 'video-1'),
      );
      await dao.addPlaylistItem(
        playlistId: playlistId,
        item: _playlistItem(playlistId, 'source-a', 'video-1'),
      );
      await dao.addPlaylistItem(
        playlistId: playlistId,
        item: _playlistItem(playlistId, 'source-a', 'video-2'),
      );

      final beforeMove = await dao.getPlaylistItems(playlistId);
      expect(beforeMove.map((item) => item.originalId), [
        'video-1',
        'video-1',
        'video-2',
      ]);
      expect(beforeMove.map((item) => item.position), [0, 1, 2]);
      expect(beforeMove.map((item) => item.internalId).toSet(), hasLength(3));

      await dao.movePlaylistItem(
        playlistId: playlistId,
        fromIndex: 0,
        toIndex: 2,
      );
      final afterMove = await dao.getPlaylistItems(playlistId);
      expect(afterMove.map((item) => item.originalId), [
        'video-1',
        'video-2',
        'video-1',
      ]);
      expect(afterMove.map((item) => item.position), [0, 1, 2]);
      expect(afterMove.map((item) => item.internalId), [
        beforeMove[1].internalId,
        beforeMove[2].internalId,
        beforeMove[0].internalId,
      ]);

      await dao.removePlaylistItem(afterMove[1].internalId);
      final afterRemoval = await dao.getPlaylistItems(playlistId);
      expect(afterRemoval.map((item) => item.originalId), [
        'video-1',
        'video-1',
      ]);
      expect(afterRemoval.map((item) => item.position), [0, 1]);
    },
  );

  test('deletes multiple playlist items by internal id', () async {
    final playlistId = await dao.createPlaylist('source-a', 'Queue');
    await dao.addPlaylistItems(
      playlistId: playlistId,
      items: [
        _playlistItem(playlistId, 'source-a', 'video-1'),
        _playlistItem(playlistId, 'source-a', 'video-2'),
        _playlistItem(playlistId, 'source-a', 'video-3'),
      ],
    );

    final before = await dao.getPlaylistItems(playlistId);
    expect(before, hasLength(3));

    await dao.deletePlaylistItems(
      playlistId: playlistId,
      itemIds: [before[0].internalId],
    );
    expect(await dao.getPlaylistItems(playlistId), hasLength(2));

    await dao.deletePlaylistItems(
      playlistId: playlistId,
      itemIds: [before[1].internalId, before[2].internalId],
    );
    expect(await dao.getPlaylistItems(playlistId), isEmpty);
  });

  test('rejects cross-source entries and rolls back a failed batch', () async {
    final playlistId = await dao.createPlaylist('source-a', 'Queue');

    await expectLater(
      dao.addPlaylistItem(
        playlistId: playlistId,
        item: _playlistItem(playlistId, 'source-b', 'video-1'),
      ),
      throwsArgumentError,
    );
    expect(await dao.getPlaylistItems(playlistId), isEmpty);

    await expectLater(
      dao.addPlaylistItems(
        playlistId: playlistId,
        items: [
          _playlistItem(playlistId, 'source-a', 'video-1'),
          _playlistItem(playlistId, 'source-a', '   '),
        ],
      ),
      throwsArgumentError,
    );
    expect(await dao.getPlaylistItems(playlistId), isEmpty);
  });

  test('preserves subscription groups across metadata upserts', () async {
    await dao.saveSubscription(_subscription('source-a', 'creator-1', 'Old'));
    await dao.setSubscriptionGroup('source-a', 'creator-1', 'Editors');
    await dao.saveSubscription(
      _subscription('source-a', 'creator-1', 'Renamed'),
    );

    final subscription = (await dao.getSubscriptions()).single;
    expect(subscription.name, 'Renamed');
    expect(subscription.groupName, 'Editors');

    await dao.setSubscriptionGroup('source-a', 'creator-1', '');
    expect((await dao.getSubscriptions()).single.groupName, isEmpty);
  });

  test('migrates a real v2 sqlite fixture without losing history', () async {
    final migrated = AppDatabase(
      NativeDatabase.memory(
        setup: (database) {
          database.execute('PRAGMA foreign_keys = ON');
          database.execute(_v2Schema);
          database.execute('PRAGMA user_version = 2');
          database.execute('''
            INSERT INTO media (
              internal_id, source_id, original_id, title, url, type
            ) VALUES (1, 'source-a', 'legacy-video', 'Legacy',
              'https://example.test/legacy-video', 'video')
          ''');
          database.execute('''
            INSERT INTO media_history (
              media_id, progress_seconds, completed
            ) VALUES (1, 42, 0)
          ''');
        },
      ),
    );

    addTearDown(migrated.close);

    final history = await migrated.mediaHistoryDao.getHistoryWithMedia();
    expect(history, hasLength(1));
    expect(history.single.media.originalId, 'legacy-video');
    expect(history.single.history.progressSeconds, BigInt.from(42));
    expect(migrated.schemaVersion, 5);
    expect(
      (await migrated.customSelect('PRAGMA user_version').getSingle())
          .read<int>('user_version'),
      5,
    );

    final playlistId = await migrated.localLibraryDao.createPlaylist(
      'source-a',
      'Migrated queue',
    );
    await migrated.localLibraryDao.addPlaylistItem(
      playlistId: playlistId,
      item: _playlistItem(playlistId, 'source-a', 'legacy-video'),
    );
    await migrated.localLibraryDao.deletePlaylist(playlistId);
    expect(
      await migrated.localLibraryDao.getPlaylistItems(playlistId),
      isEmpty,
    );

    await (migrated.delete(
      migrated.media,
    )..where((media) => media.internalId.equals(1))).go();
    expect(await migrated.mediaHistoryDao.getHistoryWithMedia(), isEmpty);
  });
}

LocalBookmarkCompanion _bookmark(
  String sourceId,
  String originalId,
  String title,
) => LocalBookmarkCompanion.insert(
  sourceId: sourceId,
  originalId: originalId,
  title: title,
  url: 'https://example.test/$originalId',
);

LocalSubscriptionCompanion _subscription(
  String sourceId,
  String originalId,
  String name,
) => LocalSubscriptionCompanion.insert(
  sourceId: sourceId,
  originalId: originalId,
  name: name,
);

LocalPlaylistItemCompanion _playlistItem(
  int playlistId,
  String sourceId,
  String originalId,
) => LocalPlaylistItemCompanion.insert(
  playlistId: playlistId,
  sourceId: sourceId,
  originalId: originalId,
  title: originalId,
  url: 'https://example.test/$originalId',
  position: 0,
);

const _v2Schema = '''
CREATE TABLE recent_search_query (
  query TEXT NOT NULL PRIMARY KEY,
  queried_date TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE media (
  internal_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  source_id TEXT NOT NULL,
  original_id TEXT NOT NULL,
  title TEXT NOT NULL,
  url TEXT NOT NULL,
  thumbnail_url TEXT,
  creator_profile_name TEXT,
  creator_profile_id TEXT,
  upload_date TEXT,
  type TEXT NOT NULL CHECK (type IN ('video', 'article', 'post')),
  UNIQUE (source_id, type, original_id)
);
CREATE TABLE media_history (
  internal_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  media_id INTEGER NOT NULL REFERENCES media (internal_id) ON DELETE CASCADE,
  accessed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  progress_seconds INTEGER,
  completed INTEGER NOT NULL DEFAULT 0,
  UNIQUE (media_id)
);
CREATE TABLE video (
  media_id INTEGER NOT NULL PRIMARY KEY REFERENCES media (internal_id) ON DELETE CASCADE,
  duration INTEGER NOT NULL,
  view_count INTEGER
);
CREATE TABLE creator_profile (
  internal_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  service_id TEXT NOT NULL,
  id TEXT NOT NULL,
  url TEXT NOT NULL,
  name TEXT NOT NULL,
  thumbnail_url TEXT,
  UNIQUE (service_id, id)
);
CREATE TABLE article (
  media_id INTEGER NOT NULL PRIMARY KEY REFERENCES media (internal_id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  author TEXT,
  word_count INTEGER
);
CREATE TABLE post (
  media_id INTEGER NOT NULL PRIMARY KEY REFERENCES media (internal_id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  image_urls_json TEXT NOT NULL
);
''';

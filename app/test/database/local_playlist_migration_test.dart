import 'package:app/database/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:test/test.dart';

void main() {
  test(
    'fresh schema creates the playlist-order index and enables foreign keys',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      expect(db.schemaVersion, 5);
      expect(await _pragmaInt(db, 'user_version'), 5);
      expect(await _pragmaInt(db, 'foreign_keys'), 1);
      await _expectPlaylistItemOrderIndex(db);
    },
  );

  test('migrates v4 playlists and local-library data without loss', () async {
    final db = _openLegacyMemory(
      schema: _v4Schema,
      version: 4,
      seed: _seedV4Data,
    );
    addTearDown(db.close);

    expect(await _pragmaInt(db, 'user_version'), 5);
    expect(await _pragmaInt(db, 'foreign_keys'), 1);
    await _expectPlaylistItemOrderIndex(db);

    final playlist = (await db.localLibraryDao.getPlaylists()).single;
    expect(playlist.internalId, 10);
    expect(playlist.sourceId, 'source-a');
    expect(playlist.name, 'Saved queue');
    expect(playlist.createdAt, DateTime.parse('2025-01-02T03:04:05.000Z'));
    expect(playlist.updatedAt, DateTime.parse('2025-01-03T04:05:06.000Z'));

    final items = await db.localLibraryDao.getPlaylistItems(
      playlist.internalId,
    );
    expect(items.map((item) => item.internalId), [101, 100, 102]);
    expect(items.map((item) => item.position), [2, 7, 11]);
    expect(items.map((item) => item.sourceId), [
      'source-a',
      'source-a',
      'source-b',
    ]);
    expect(items.map((item) => item.originalId), [
      'video-duplicate',
      'video-duplicate',
      'other-source-video',
    ]);
    expect(items.map((item) => item.title), [
      'Duplicate second',
      'Duplicate first',
      'Other source title',
    ]);
    expect(items.map((item) => item.url), [
      'https://example.test/duplicate-second',
      'https://example.test/duplicate-first',
      'https://example.test/other-source-video',
    ]);
    expect(items.map((item) => item.thumbnailUrl), [
      'https://img.test/second.jpg',
      null,
      'https://img.test/other.jpg',
    ]);
    expect(items.map((item) => item.addedAt), [
      DateTime.parse('2025-01-05T06:07:08.000Z'),
      DateTime.parse('2025-01-04T05:06:07.000Z'),
      DateTime.parse('2025-01-06T07:08:09.000Z'),
    ]);

    final bookmarks = await db.localLibraryDao.getBookmarks();
    expect(bookmarks, hasLength(1));
    expect(bookmarks.single.sourceId, 'source-a');
    expect(bookmarks.single.originalId, 'bookmarked-video');
    expect(bookmarks.single.title, 'Bookmarked title');
    expect(bookmarks.single.url, 'https://example.test/bookmarked-video');
    expect(bookmarks.single.thumbnailUrl, 'https://img.test/bookmark.jpg');
    expect(bookmarks.single.creatorProfileId, 'creator-1');
    expect(bookmarks.single.creatorProfileName, 'Creator One');
    expect(
      bookmarks.single.createdAt,
      DateTime.parse('2025-01-07T08:09:10.000Z'),
    );

    final subscriptions = await db.localLibraryDao.getSubscriptions();
    expect(subscriptions, hasLength(1));
    expect(subscriptions.single.sourceId, 'source-a');
    expect(subscriptions.single.originalId, 'creator-1');
    expect(subscriptions.single.name, 'Creator One');
    expect(subscriptions.single.thumbnailUrl, 'https://img.test/creator.jpg');
    expect(subscriptions.single.groupName, 'Editors');
    expect(
      subscriptions.single.subscribedAt,
      DateTime.parse('2025-01-08T09:10:11.000Z'),
    );

    final history = await db.mediaHistoryDao.getHistoryWithMedia();
    expect(history, hasLength(1));
    expect(history.single.media.internalId, 1);
    expect(history.single.media.sourceId, 'source-a');
    expect(history.single.media.originalId, 'watched-video');
    expect(history.single.media.title, 'Watched title');
    expect(history.single.media.url, 'https://example.test/watched-video');
    expect(history.single.media.thumbnailUrl, 'https://img.test/watched.jpg');
    expect(history.single.media.creatorProfileId, 'creator-1');
    expect(history.single.media.creatorProfileName, 'Creator One');
    expect(history.single.history.progressSeconds, BigInt.from(73));
    expect(history.single.history.completed, isTrue);
    expect(
      history.single.history.accessedAt,
      DateTime.parse('2025-01-09T10:11:12.000Z'),
    );

    final creator = await db.creatorProfileDao.getCreatorProfile(
      'source-a',
      'creator-1',
    );
    expect(creator?.url, 'https://example.test/creator-1');
    expect(creator?.name, 'Creator One');
    expect(creator?.thumbnailUrl, 'https://img.test/creator.jpg');
    expect(creator?.description, 'A preserved creator description');
    expect(creator?.subscribers, 1234);
    expect(creator?.videos, 56);

    await db.localLibraryDao.addPlaylistItem(
      playlistId: playlist.internalId,
      item: LocalPlaylistItemCompanion.insert(
        playlistId: playlist.internalId,
        sourceId: 'source-a',
        originalId: 'appended-video',
        title: 'Appended title',
        url: 'https://example.test/appended-video',
        position: 99,
      ),
    );
    final appended = await db.localLibraryDao.getPlaylistItems(
      playlist.internalId,
    );
    expect(appended.map((item) => item.originalId), [
      'video-duplicate',
      'video-duplicate',
      'other-source-video',
      'appended-video',
    ]);
    expect(appended.map((item) => item.position), [2, 7, 11, 12]);

    await db.localLibraryDao.movePlaylistItem(
      playlistId: playlist.internalId,
      fromIndex: 0,
      toIndex: 3,
    );
    final reordered = await db.localLibraryDao.getPlaylistItems(
      playlist.internalId,
    );
    expect(reordered.map((item) => item.originalId), [
      'video-duplicate',
      'other-source-video',
      'appended-video',
      'video-duplicate',
    ]);
    expect(reordered.map((item) => item.position), [0, 1, 2, 3]);
    expect(
      reordered.map((item) => item.internalId.toString()).toSet(),
      hasLength(4),
    );

    final searchMatches = await db.localLibraryDao.getPlaylistItems(
      playlist.internalId,
      query: 'Other source',
    );
    expect(searchMatches.map((item) => item.originalId), [
      'other-source-video',
    ]);

    await db.localLibraryDao.deletePlaylist(playlist.internalId);
    expect(
      await db.localLibraryDao.getPlaylistItems(playlist.internalId),
      isEmpty,
    );
  });

  test(
    'reopens a migrated database without repeating its index migration',
    () async {
      final raw = sqlite.sqlite3.openInMemory();
      var rawClosed = false;
      addTearDown(() {
        if (!rawClosed) raw.close();
      });
      _installSchema(raw, _v4Schema, version: 4);
      _seedV4Data(raw);

      final first = _open(raw);
      try {
        expect(await _pragmaInt(first, 'user_version'), 5);
        await _expectPlaylistItemOrderIndex(first);
        expect(await first.localLibraryDao.getBookmarks(), hasLength(1));
      } finally {
        await first.close();
      }

      final reopened = _open(raw);
      try {
        expect(await _pragmaInt(reopened, 'user_version'), 5);
        await _expectPlaylistItemOrderIndex(reopened);
        expect(await reopened.localLibraryDao.getPlaylists(), hasLength(1));
        expect(
          await reopened.localLibraryDao.getPlaylistItems(10),
          hasLength(3),
        );
      } finally {
        await reopened.close();
        raw.close();
        rawClosed = true;
      }
    },
  );

  test('migrates the authentic v3 schema through v4 and v5', () async {
    final db = _openLegacyMemory(
      schema: _v3Schema,
      version: 3,
      seed: (raw) {
        raw.execute('''
      INSERT INTO creator_profile (
        internal_id, service_id, id, url, name, thumbnail_url
      ) VALUES (1, 'source-a', 'creator-3',
        'https://example.test/creator-3', 'Legacy creator',
        'https://img.test/creator-3.jpg')
    ''');
        raw.execute('''
      INSERT INTO local_playlist (
        internal_id, source_id, name, created_at, updated_at
      ) VALUES (20, 'source-a', 'v3 queue',
        '2024-03-02T03:04:05.000Z', '2024-03-03T04:05:06.000Z')
    ''');
        raw.execute('''
      INSERT INTO local_playlist_item (
        internal_id, playlist_id, source_id, original_id, title, url,
        thumbnail_url, position, added_at
      ) VALUES (200, 20, 'source-a', 'v3-video', 'V3 title',
        'https://example.test/v3-video', 'https://img.test/v3.jpg', 4,
        '2024-03-04T05:06:07.000Z')
    ''');
      },
    );
    addTearDown(db.close);

    expect(await _pragmaInt(db, 'user_version'), 5);
    await _expectPlaylistItemOrderIndex(db);
    expect((await db.localLibraryDao.getPlaylists()).single.name, 'v3 queue');
    final item = (await db.localLibraryDao.getPlaylistItems(20)).single;
    expect(item.originalId, 'v3-video');
    expect(item.position, 4);
    expect(item.addedAt, DateTime.parse('2024-03-04T05:06:07.000Z'));

    final creator = await db.creatorProfileDao.getCreatorProfile(
      'source-a',
      'creator-3',
    );
    expect(creator?.name, 'Legacy creator');
    expect(creator?.description, isNull);
    expect(creator?.subscribers, isNull);
    expect(creator?.videos, isNull);
  });
}

AppDatabase _open(sqlite.Database raw) => AppDatabase(
  DatabaseConnection(
    NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
    closeStreamsSynchronously: true,
  ),
);

AppDatabase _openLegacyMemory({
  required String schema,
  required int version,
  void Function(sqlite.Database raw)? seed,
}) => AppDatabase(
  NativeDatabase.memory(
    setup: (raw) {
      _installSchema(raw, schema, version: version);
      seed?.call(raw);
    },
  ),
);

void _installSchema(
  sqlite.Database raw,
  String schema, {
  required int version,
}) {
  raw.execute('PRAGMA foreign_keys = ON');
  raw.execute(schema);
  raw.execute('PRAGMA user_version = $version');
}

Future<int> _pragmaInt(AppDatabase db, String pragma) async =>
    (await db.customSelect('PRAGMA $pragma').getSingle()).read<int>(pragma);

Future<void> _expectPlaylistItemOrderIndex(AppDatabase db) async {
  final index = await db.customSelect('''
    SELECT name
    FROM sqlite_master
    WHERE type = 'index' AND name = 'local_playlist_item_order'
  ''').get();
  expect(index, hasLength(1));

  final columns = await db
      .customSelect("PRAGMA index_info('local_playlist_item_order')")
      .get();
  expect(columns.map((row) => row.read<String>('name')), [
    'playlist_id',
    'position',
    'internal_id',
  ]);
}

void _seedV4Data(sqlite.Database raw) {
  raw.execute('''
    INSERT INTO media (
      internal_id, source_id, original_id, title, url, thumbnail_url,
      creator_profile_name, creator_profile_id, upload_date, type
    ) VALUES (1, 'source-a', 'watched-video', 'Watched title',
      'https://example.test/watched-video', 'https://img.test/watched.jpg',
      'Creator One', 'creator-1', '2025-01-01T00:00:00.000Z', 'video'),
      (2, 'source-b', 'other-video', 'Other title',
      'https://example.test/other-video', NULL, NULL, NULL, NULL, 'video')
  ''');
  raw.execute('''
    INSERT INTO media_history (
      internal_id, media_id, accessed_at, progress_seconds, completed
    ) VALUES (1, 1, '2025-01-09T10:11:12.000Z', 73, 1)
  ''');
  raw.execute('''
    INSERT INTO creator_profile (
      internal_id, service_id, id, url, name, thumbnail_url,
      description, subscribers, videos
    ) VALUES (1, 'source-a', 'creator-1',
      'https://example.test/creator-1', 'Creator One',
      'https://img.test/creator.jpg', 'A preserved creator description',
      1234, 56)
  ''');
  raw.execute('''
    INSERT INTO local_bookmark (
      internal_id, source_id, original_id, title, url, thumbnail_url,
      creator_profile_id, creator_profile_name, created_at
    ) VALUES (1, 'source-a', 'bookmarked-video', 'Bookmarked title',
      'https://example.test/bookmarked-video', 'https://img.test/bookmark.jpg',
      'creator-1', 'Creator One', '2025-01-07T08:09:10.000Z')
  ''');
  raw.execute('''
    INSERT INTO local_subscription (
      internal_id, source_id, original_id, name, thumbnail_url,
      group_name, subscribed_at
    ) VALUES (1, 'source-a', 'creator-1', 'Creator One',
      'https://img.test/creator.jpg', 'Editors', '2025-01-08T09:10:11.000Z')
  ''');
  raw.execute('''
    INSERT INTO local_playlist (
      internal_id, source_id, name, created_at, updated_at
    ) VALUES (10, 'source-a', 'Saved queue',
      '2025-01-02T03:04:05.000Z', '2025-01-03T04:05:06.000Z')
  ''');
  raw.execute('''
    INSERT INTO local_playlist_item (
      internal_id, playlist_id, source_id, original_id, title, url,
      thumbnail_url, position, added_at
    ) VALUES
      (100, 10, 'source-a', 'video-duplicate', 'Duplicate first',
        'https://example.test/duplicate-first', NULL, 7,
        '2025-01-04T05:06:07.000Z'),
      (101, 10, 'source-a', 'video-duplicate', 'Duplicate second',
        'https://example.test/duplicate-second', 'https://img.test/second.jpg',
        2, '2025-01-05T06:07:08.000Z'),
      (102, 10, 'source-b', 'other-source-video', 'Other source title',
        'https://example.test/other-source-video', 'https://img.test/other.jpg',
        11, '2025-01-06T07:08:09.000Z')
  ''');
}

const _v3Schema = '''
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
CREATE TABLE local_bookmark (
  internal_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  source_id TEXT NOT NULL,
  original_id TEXT NOT NULL,
  title TEXT NOT NULL,
  url TEXT NOT NULL,
  thumbnail_url TEXT,
  creator_profile_id TEXT,
  creator_profile_name TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (source_id, original_id)
);
CREATE TABLE local_playlist (
  internal_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  source_id TEXT NOT NULL,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (source_id, name)
);
CREATE TABLE local_playlist_item (
  internal_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  playlist_id INTEGER NOT NULL REFERENCES local_playlist (internal_id) ON DELETE CASCADE,
  source_id TEXT NOT NULL,
  original_id TEXT NOT NULL,
  title TEXT NOT NULL,
  url TEXT NOT NULL,
  thumbnail_url TEXT,
  position INTEGER NOT NULL,
  added_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE local_subscription (
  internal_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  source_id TEXT NOT NULL,
  original_id TEXT NOT NULL,
  name TEXT NOT NULL,
  thumbnail_url TEXT,
  group_name TEXT NOT NULL DEFAULT '',
  subscribed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (source_id, original_id)
);
''';

const _v4Schema = '''
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
  description TEXT,
  subscribers INTEGER,
  videos INTEGER,
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
CREATE TABLE local_bookmark (
  internal_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  source_id TEXT NOT NULL,
  original_id TEXT NOT NULL,
  title TEXT NOT NULL,
  url TEXT NOT NULL,
  thumbnail_url TEXT,
  creator_profile_id TEXT,
  creator_profile_name TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (source_id, original_id)
);
CREATE TABLE local_playlist (
  internal_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  source_id TEXT NOT NULL,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (source_id, name)
);
CREATE TABLE local_playlist_item (
  internal_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  playlist_id INTEGER NOT NULL REFERENCES local_playlist (internal_id) ON DELETE CASCADE,
  source_id TEXT NOT NULL,
  original_id TEXT NOT NULL,
  title TEXT NOT NULL,
  url TEXT NOT NULL,
  thumbnail_url TEXT,
  position INTEGER NOT NULL,
  added_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE local_subscription (
  internal_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  source_id TEXT NOT NULL,
  original_id TEXT NOT NULL,
  name TEXT NOT NULL,
  thumbnail_url TEXT,
  group_name TEXT NOT NULL DEFAULT '',
  subscribed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (source_id, original_id)
);
''';

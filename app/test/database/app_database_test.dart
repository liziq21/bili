import 'package:app/database/app_database.dart';
import 'package:app/database/table/media.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('RecentSearchQueryDao', () {
    test('trims queries, strips control characters, and ignores whitespace/control-only searches', () async {
      final dao = db.recentSearchQueryDao;

      await dao.insertOrReplaceRecentSearch('  query\x00\x1F\x7F  ');
      await dao.insertOrReplaceRecentSearch(' \t\n\x00 ');

      final queries = await dao.getRecentSearchQueryEntities(10).first;
      expect(queries.map((query) => query.query), equals(['query']));
    });

    test(
      'truncates searches exceeding max length constraint (200 chars)',
      () async {
        final dao = db.recentSearchQueryDao;
        final longQuery = 'A' * 250;

        await dao.insertOrReplaceRecentSearch(longQuery);

        final queries = await dao.getRecentSearchQueryEntities(10).first;
        expect(queries, hasLength(1));
        expect(queries.first.query.length, equals(200));
        expect(queries.first.query, equals('A' * 200));
      },
    );

    test('truncates at a complete Unicode character boundary', () async {
      final dao = db.recentSearchQueryDao;
      final queryAtBoundary = '${'A' * 199}😀';

      await dao.insertOrReplaceRecentSearch(queryAtBoundary);

      final queries = await dao.getRecentSearchQueryEntities(10).first;
      expect(queries, hasLength(1));
      expect(queries.first.query, equals('A' * 199));
    });

    test('trims whitespace exposed by truncation', () async {
      final dao = db.recentSearchQueryDao;
      final queryWithBoundaryWhitespace = '${'A' * 199} B';

      await dao.insertOrReplaceRecentSearch(queryWithBoundaryWhitespace);

      final queries = await dao.getRecentSearchQueryEntities(10).first;
      expect(queries, hasLength(1));
      expect(queries.first.query, equals('A' * 199));
    });

    test(
      'inserts, orders descending, and updates timestamp on re-search',
      () async {
        final dao = db.recentSearchQueryDao;

        await dao.insertOrReplaceRecentSearch('query 1');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await dao.insertOrReplaceRecentSearch('query 2');

        final list1 = await dao.getRecentSearchQueryEntities(10).first;
        expect(
          list1.map((e) => e.query).toList(),
          equals(['query 2', 'query 1']),
        );

        // Re-search 'query 1' should update timestamp and bring it to top
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await dao.insertOrReplaceRecentSearch('query 1');

        final list2 = await dao.getRecentSearchQueryEntities(10).first;
        expect(
          list2.map((e) => e.query).toList(),
          equals(['query 1', 'query 2']),
        );

        await dao.clearRecentSearchQueries();
        final list3 = await dao.getRecentSearchQueryEntities(10).first;
        expect(list3, isEmpty);
      },
    );
  });

  group('VideoDao', () {
    test(
      'inserts and retrieves video with media, and handles upsert correctly',
      () async {
        final dao = db.videoDao;

        const mediaCompanion = MediaCompanion(
          sourceId: Value('bilibili'),
          originalId: Value('BV12345'),
          title: Value('Test Video'),
          url: Value('https://www.bilibili.com/video/BV12345'),
          thumbnailUrl: Value('https://pic.bilibili.com/cover.jpg'),
        );

        final videoCompanion = VideoCompanion(
          duration: Value(BigInt.from(300)),
          viewCount: Value(BigInt.from(10000)),
        );

        await dao.insertVideo((mediaCompanion, videoCompanion));

        final result1 = await dao.getVideoMedia('bilibili', 'BV12345');
        expect(result1, isNotNull);
        expect(result1!.$1.title, equals('Test Video'));
        expect(result1.$1.type, equals(Media.typeVideo));
        expect(result1.$2.duration, equals(BigInt.from(300)));

        // Upsert: update title and viewCount
        const updatedMedia = MediaCompanion(
          sourceId: Value('bilibili'),
          originalId: Value('BV12345'),
          title: Value('Test Video Updated'),
          url: Value('https://www.bilibili.com/video/BV12345'),
          thumbnailUrl: Value('https://pic.bilibili.com/cover_new.jpg'),
        );

        final updatedVideo = VideoCompanion(
          duration: Value(BigInt.from(300)),
          viewCount: Value(BigInt.from(20000)),
        );

        await dao.insertVideo((updatedMedia, updatedVideo));

        final result2 = await dao.getVideoMedia('bilibili', 'BV12345');
        expect(result2, isNotNull);
        expect(result2!.$1.internalId, equals(result1.$1.internalId));
        expect(result2.$1.title, equals('Test Video Updated'));
        expect(result2.$2.viewCount, equals(BigInt.from(20000)));
      },
    );
  });

  group('ArticleDao', () {
    test('inserts and retrieves article with media', () async {
      final dao = db.articleDao;

      const mediaCompanion = MediaCompanion(
        sourceId: Value('bilibili'),
        originalId: Value('cv12345'),
        title: Value('Test Article'),
        url: Value('https://www.bilibili.com/read/cv12345'),
        thumbnailUrl: Value('https://pic.bilibili.com/article.jpg'),
      );

      final articleCompanion = ArticleCompanion(
        content: const Value('Article content text'),
        author: const Value('Author Name'),
        wordCount: Value(BigInt.from(1500)),
      );

      await dao.insertArticle((mediaCompanion, articleCompanion));

      final result = await dao.getArticleMedia('bilibili', 'cv12345');
      expect(result, isNotNull);
      expect(result!.$1.title, equals('Test Article'));
      expect(result.$1.type, equals(Media.typeArticle));
      expect(result.$2.content, equals('Article content text'));
    });
  });

  group('PostDao', () {
    test('inserts and retrieves post with media', () async {
      final dao = db.postDao;

      const mediaCompanion = MediaCompanion(
        sourceId: Value('bilibili'),
        originalId: Value('post999'),
        title: Value('Test Post'),
        url: Value('https://t.bilibili.com/post999'),
        thumbnailUrl: Value('https://pic.bilibili.com/post.jpg'),
      );

      const postCompanion = PostCompanion(
        content: Value('Post content body'),
        imageUrlsJson: Value('["https://pic.bilibili.com/1.jpg"]'),
      );

      await dao.insertPost((mediaCompanion, postCompanion));

      final result = await dao.getPostMedia('bilibili', 'post999');
      expect(result, isNotNull);
      expect(result!.$1.title, equals('Test Post'));
      expect(result.$1.type, equals(Media.typePost));
      expect(result.$2.content, equals('Post content body'));
    });
  });

  group('CreatorProfileDao', () {
    test('inserts, upserts, and retrieves creator profile', () async {
      final dao = db.creatorProfileDao;

      const profile = CreatorProfileCompanion(
        serviceId: Value('bilibili'),
        id: Value('mid_123'),
        name: Value('UP Main'),
        url: Value('https://space.bilibili.com/123'),
        thumbnailUrl: Value('https://pic.bilibili.com/avatar.jpg'),
      );

      await dao.upsertCreatorProfile(profile);

      final fetched = await dao.getCreatorProfile('bilibili', 'mid_123');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('UP Main'));

      // Update name via upsert
      const updatedProfile = CreatorProfileCompanion(
        serviceId: Value('bilibili'),
        id: Value('mid_123'),
        name: Value('UP Main Renamed'),
        url: Value('https://space.bilibili.com/123'),
        thumbnailUrl: Value('https://pic.bilibili.com/avatar.jpg'),
      );

      await dao.upsertCreatorProfile(updatedProfile);
      final fetchedUpdated = await dao.getCreatorProfile('bilibili', 'mid_123');
      expect(fetchedUpdated!.name, equals('UP Main Renamed'));
      expect(fetchedUpdated.internalId, equals(fetched.internalId));
    });
  });

  group('MediaHistoryDao', () {
    test('inserts history and queries with joined media', () async {
      final videoDao = db.videoDao;
      final historyDao = db.mediaHistoryDao;

      const mediaCompanion = MediaCompanion(
        sourceId: Value('bilibili'),
        originalId: Value('BV_HIST_1'),
        title: Value('History Video'),
        url: Value('https://www.bilibili.com/video/BV_HIST_1'),
        thumbnailUrl: Value('https://pic.bilibili.com/cover.jpg'),
      );
      final videoCompanion = VideoCompanion(duration: Value(BigInt.from(120)));

      await videoDao.insertVideo((mediaCompanion, videoCompanion));
      final videoMedia = await videoDao.getVideoMedia('bilibili', 'BV_HIST_1');

      await historyDao.insertMediaHistory(
        MediaHistoryCompanion(
          mediaId: Value(videoMedia!.$1.internalId),
          progressSeconds: Value(BigInt.from(60)),
        ),
      );

      final historyList = await historyDao.getHistoryWithMedia();
      expect(historyList, hasLength(1));
      expect(historyList.first.media.title, equals('History Video'));
      expect(
        historyList.first.history.progressSeconds,
        equals(BigInt.from(60)),
      );
    });

    test('saveProgress updates the existing media history row', () async {
      final historyDao = db.mediaHistoryDao;

      final mediaId = await historyDao.getOrCreateMediaId(
        'bilibili',
        'BV_PROGRESS',
        Media.typeVideo,
        title: 'A title',
        url: 'https://example.com/video',
      );
      expect(
        await historyDao.getOrCreateMediaId(
          'bilibili',
          'BV_PROGRESS',
          Media.typeVideo,
        ),
        mediaId,
      );
      await historyDao.saveProgress(mediaId, 10);
      await historyDao.saveProgress(mediaId, 42);

      expect(await historyDao.getProgressForMedia(mediaId), 42);
      final rows = await historyDao.getHistoryWithMedia();
      expect(rows, hasLength(1));
      expect(rows.single.media.title, 'A title');
      expect(rows.single.media.url, 'https://example.com/video');
    });

    test('backfills title and cover when metadata arrives later', () async {
      final historyDao = db.mediaHistoryDao;

      // 进度读取先于详情：第一调用只拿得到 id，行里只能先放原始 id。
      final mediaId = await historyDao.getOrCreateMediaId(
        'bilibili',
        'BV_META',
        Media.typeVideo,
      );
      var rows = await historyDao.getHistoryWithMedia();
      expect(rows.single.media.title, 'BV_META');
      expect(rows.single.media.thumbnailUrl, null);

      // 详情到达后补写元数据，历史列表才能显示标题与封面。
      expect(
        await historyDao.getOrCreateMediaId(
          'bilibili',
          'BV_META',
          Media.typeVideo,
          title: 'A real title',
          url: 'https://www.bilibili.com/video/BV_META',
          thumbnailUrl: 'https://example.com/cover.jpg',
          creatorProfileName: 'UP',
          creatorProfileId: '42',
        ),
        mediaId,
      );

      rows = await historyDao.getHistoryWithMedia();
      expect(rows, hasLength(1));
      expect(rows.single.media.title, 'A real title');
      expect(rows.single.media.thumbnailUrl, 'https://example.com/cover.jpg');
      expect(rows.single.media.creatorProfileName, 'UP');
    });

    test('findMediaId never creates a history row', () async {
      final historyDao = db.mediaHistoryDao;

      // Given 一条还没被看过的视频。
      // When 只用读路径查它（打开视频页恢复进度走的就是这条路径）。
      final missing = await historyDao.findMediaId(
        'bilibili',
        'BV_UNSEEN',
        Media.typeVideo,
      );

      // Then 查不到，而且没有凭空多出一条只有原始 id 的历史记录。
      // `isNull` 在 drift 与 matcher 之间同名冲突，这里用字面量 null。
      expect(missing, null);
      expect(await historyDao.getHistoryWithMedia(), isEmpty);
    });

    test('findMediaId returns the id created by the write path', () async {
      final historyDao = db.mediaHistoryDao;

      // Given 一条已经写过进度的视频。
      final created = await historyDao.getOrCreateMediaId(
        'bilibili',
        'BV_SEEN',
        Media.typeVideo,
        title: 'Seen',
      );

      // When 读路径查同一个 (sourceId, originalId, type)。
      final found = await historyDao.findMediaId(
        'bilibili',
        'BV_SEEN',
        Media.typeVideo,
      );

      // Then 拿到同一行，历史记录数不变。
      expect(found, created);
      expect(await historyDao.getHistoryWithMedia(), hasLength(1));
    });

    test(
      'deleteHistoryForMediaKey removes only the matching history row',
      () async {
        final historyDao = db.mediaHistoryDao;
        await historyDao.getOrCreateMediaId(
          'bilibili',
          'BV_KEEP',
          Media.typeVideo,
          title: 'Keep',
          url: 'https://example.com/keep',
        );
        await historyDao.getOrCreateMediaId(
          'bilibili',
          'BV_DROP',
          Media.typeVideo,
          title: 'Drop',
          url: 'https://example.com/drop',
        );
        // 同一 originalId 挂在另一个数据源下是另一行（media 唯一键含 sourceId），
        // 按 {sourceId, originalId} 删除时不能连带删掉它。
        await historyDao.getOrCreateMediaId(
          'youtube',
          'BV_DROP',
          Media.typeVideo,
          title: 'Other source',
          url: 'https://example.com/other',
        );

        final deleted = await historyDao.deleteHistoryForMediaKey(
          sourceId: 'bilibili',
          originalId: 'BV_DROP',
        );

        expect(deleted, 1);
        final remaining = await historyDao.getHistoryWithMedia();
        expect(
          remaining.map(
            (row) => '${row.media.sourceId}/${row.media.originalId}',
          ),
          unorderedEquals(['bilibili/BV_KEEP', 'youtube/BV_DROP']),
        );
      },
    );

    test('deleting history keeps the media row it pointed at', () async {
      final historyDao = db.mediaHistoryDao;
      await historyDao.getOrCreateMediaId(
        'bilibili',
        'BV_MEDIA_KEPT',
        Media.typeVideo,
        title: 'Kept media',
        url: 'https://example.com/kept',
      );

      await historyDao.deleteHistoryForMediaKey(
        sourceId: 'bilibili',
        originalId: 'BV_MEDIA_KEPT',
      );

      expect(await historyDao.getHistoryWithMedia(), isEmpty);
      // media 是元数据缓存（时长、播放量、封面），详情页直接读它；清历史不该连它一起删。
      final media = await db.select(db.media).get();
      expect(media.map((row) => row.originalId), ['BV_MEDIA_KEPT']);
    });

    test(
      'clearHistory empties the table without touching media rows',
      () async {
        final historyDao = db.mediaHistoryDao;
        for (final id in ['BV_C1', 'BV_C2', 'BV_C3']) {
          await historyDao.getOrCreateMediaId(
            'bilibili',
            id,
            Media.typeVideo,
            title: id,
            url: 'https://example.com/$id',
          );
        }
        expect(await historyDao.getHistoryWithMedia(), hasLength(3));

        final deleted = await historyDao.clearHistory();

        expect(deleted, 3);
        expect(await historyDao.getHistoryWithMedia(), isEmpty);
        expect(await db.select(db.media).get(), hasLength(3));
      },
    );
  });
}

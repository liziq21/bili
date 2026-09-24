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
  });
}

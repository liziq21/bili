import 'package:app/database/app_database.dart';
import 'package:app/feature/media_library/media_history_cubit.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// 构造一条观看历史：[MediaHistoryDao.getHistoryWithMedia] 按 accessedAt 倒序，
  /// 时间戳因此同时充当排序键。
  Future<void> addVideo(
    String originalId, {
    required String sourceId,
    required int minutesAgo,
  }) async {
    await db.videoDao.insertVideo((
      MediaCompanion(
        sourceId: Value(sourceId),
        originalId: Value(originalId),
        title: Value('Video $originalId'),
        url: Value('https://example.com/$originalId'),
      ),
      VideoCompanion(duration: Value(BigInt.from(60))),
    ));
    final media = await db.videoDao.getVideoMedia(sourceId, originalId);
    await db.mediaHistoryDao.insertMediaHistory(
      MediaHistoryCompanion(
        mediaId: Value(media!.$1.internalId),
        accessedAt: Value(
          DateTime(2026).subtract(Duration(minutes: minutesAgo)),
        ),
      ),
    );
  }

  Future<void> addArticle(
    String originalId, {
    required String sourceId,
    required int minutesAgo,
  }) async {
    await db.articleDao.insertArticle((
      MediaCompanion(
        sourceId: Value(sourceId),
        originalId: Value(originalId),
        title: Value('Article $originalId'),
        url: Value('https://example.com/$originalId'),
      ),
      ArticleCompanion(content: const Value('body')),
    ));
    final media = await db.articleDao.getArticleMedia(sourceId, originalId);
    await db.mediaHistoryDao.insertMediaHistory(
      MediaHistoryCompanion(
        mediaId: Value(media!.$1.internalId),
        accessedAt: Value(
          DateTime(2026).subtract(Duration(minutes: minutesAgo)),
        ),
      ),
    );
  }

  /// 等一次加载结束。构造器已经触发首屏加载，这里等它落地。
  Future<void> settle(MediaHistoryCubit cubit) async {
    if (!cubit.state.isLoading) return;
    await cubit.stream
        .firstWhere((state) => !state.isLoading)
        .timeout(const Duration(seconds: 10));
  }

  List<String> idsOf(MediaHistoryCubit cubit) => [
    for (final item in cubit.state.items) item.video.id,
  ];

  test('the next page starts after every consumed row, not after every shown video', () async {
    // Rows newest first: article, video1, article, article, video2, article.
    // The first page of three rows holds a single video, so a second page
    // requested at offset 1 (one shown video) would hand back video1 again.
    await addArticle('a1', sourceId: 'bilibili', minutesAgo: 1);
    await addVideo('v1', sourceId: 'bilibili', minutesAgo: 2);
    await addArticle('a2', sourceId: 'bilibili', minutesAgo: 3);
    await addArticle('a3', sourceId: 'bilibili', minutesAgo: 4);
    await addVideo('v2', sourceId: 'bilibili', minutesAgo: 5);
    await addArticle('a4', sourceId: 'bilibili', minutesAgo: 6);

    final cubit = MediaHistoryCubit(
      mediaHistoryDao: db.mediaHistoryDao,
      pageSize: 3,
    );
    await settle(cubit);
    expect(idsOf(cubit), ['v1']);

    await cubit.loadMore();
    await settle(cubit);
    expect(idsOf(cubit), ['v1', 'v2']);
    // Six rows over pages of three is two full pages, so the end is only known
    // after the third read comes back short.
    expect(cubit.state.hasMore, isTrue);

    await cubit.loadMore();
    await settle(cubit);
    expect(idsOf(cubit), ['v1', 'v2']);
    expect(cubit.state.hasMore, isFalse);

    await cubit.close();
  });

  test(
    'a page without videos keeps loading until it reaches the videos',
    () async {
      await addArticle('a1', sourceId: 'bilibili', minutesAgo: 1);
      await addArticle('a2', sourceId: 'bilibili', minutesAgo: 2);
      await addArticle('a3', sourceId: 'bilibili', minutesAgo: 3);
      await addArticle('a4', sourceId: 'bilibili', minutesAgo: 4);
      await addVideo('v1', sourceId: 'bilibili', minutesAgo: 5);

      final cubit = MediaHistoryCubit(
        mediaHistoryDao: db.mediaHistoryDao,
        pageSize: 2,
      );
      await settle(cubit);

      // Stopping at the first empty page would leave the list empty while later
      // pages hold a video, and the load-more button is disabled on an empty list.
      expect(idsOf(cubit), ['v1']);
      expect(cubit.state.hasMore, isFalse);

      await cubit.close();
    },
  );

  test('a source id shared by two sources stays attached to its own item', () async {
    // media's unique key is {sourceId, type, originalId}, so the same originalId
    // can be stored once per source. Keying a map by originalId alone would let
    // the later row overwrite the earlier one.
    await addVideo('shared', sourceId: 'bilibili', minutesAgo: 1);
    await addVideo('shared', sourceId: 'youtube', minutesAgo: 2);

    final cubit = MediaHistoryCubit(
      mediaHistoryDao: db.mediaHistoryDao,
      pageSize: 10,
    );
    await settle(cubit);

    expect(
      [for (final item in cubit.state.items) item.sourceId],
      ['bilibili', 'youtube'],
    );

    await cubit.close();
  });

  test(
    'refresh drops the later pages and restarts from the first row',
    () async {
      await addVideo('v1', sourceId: 'bilibili', minutesAgo: 1);
      await addVideo('v2', sourceId: 'bilibili', minutesAgo: 2);
      await addVideo('v3', sourceId: 'bilibili', minutesAgo: 3);
      await addVideo('v4', sourceId: 'bilibili', minutesAgo: 4);

      final cubit = MediaHistoryCubit(
        mediaHistoryDao: db.mediaHistoryDao,
        pageSize: 2,
      );
      await settle(cubit);
      expect(idsOf(cubit), ['v1', 'v2']);

      await cubit.loadMore();
      await settle(cubit);
      expect(idsOf(cubit), ['v1', 'v2', 'v3', 'v4']);

      await cubit.refresh();
      await settle(cubit);
      expect(idsOf(cubit), ['v1', 'v2']);

      await cubit.close();
    },
  );
}

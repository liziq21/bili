import 'package:app/database/app_database.dart';
import 'package:app/database/dao/media_history_dao.dart';
import 'package:app/database/table/media.dart';
import 'package:app/feature/media_library/media_history_cubit.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
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

  test('visible history updates when playback progress is saved', () async {
    await addVideo('v1', sourceId: 'bilibili', minutesAgo: 1);
    final media = await db.videoDao.getVideoMedia('bilibili', 'v1');

    final cubit = MediaHistoryCubit(
      mediaHistoryDao: db.mediaHistoryDao,
      pageSize: 10,
    );
    await settle(cubit);

    final key = (sourceId: 'bilibili', originalId: 'v1');
    expect(cubit.state.progressByMedia[key], isNotNull);
    expect(cubit.state.progressByMedia[key]!.progressSeconds, isNull);
    expect(cubit.state.progressByMedia[key]!.completed, isFalse);

    await db.mediaHistoryDao.saveProgress(
      media!.$1.internalId,
      42,
      completed: true,
    );
    final updated = await cubit.stream
        .firstWhere(
          (state) =>
              state.progressByMedia[key]?.progressSeconds == 42 &&
              state.progressByMedia[key]?.completed == true,
        )
        .timeout(const Duration(seconds: 10));

    expect(updated.items, hasLength(1));
    expect(updated.items.single.video.id, 'v1');
    expect(
      updated.progressFor(updated.items.single),
      const MediaHistoryProgress(progressSeconds: 42, completed: true),
    );

    await cubit.close();
  });

  test('removeItem deletes the row and drops it from the list', () async {
    await addVideo('v1', sourceId: 'bilibili', minutesAgo: 1);
    await addVideo('v2', sourceId: 'bilibili', minutesAgo: 2);

    final cubit = MediaHistoryCubit(
      mediaHistoryDao: db.mediaHistoryDao,
      pageSize: 10,
    );
    await settle(cubit);
    final target = cubit.state.items.firstWhere(
      (item) => item.video.id == 'v1',
    );

    expect(await cubit.removeItem(target), isTrue);

    expect(idsOf(cubit), ['v2']);
    expect(
      cubit.state.progressByMedia,
      isNot(contains((sourceId: 'bilibili', originalId: 'v1'))),
    );
    // 数据库里也没了：只看内存列表的话，重进页面又会冒出来。
    final rows = await db.mediaHistoryDao.getHistoryWithMedia();
    expect(rows.map((row) => row.media.originalId), ['v2']);

    await cubit.close();
  });

  test('removeItem only removes the item from its own source', () async {
    await addVideo('shared', sourceId: 'bilibili', minutesAgo: 1);
    await addVideo('shared', sourceId: 'youtube', minutesAgo: 2);

    final cubit = MediaHistoryCubit(
      mediaHistoryDao: db.mediaHistoryDao,
      pageSize: 10,
    );
    await settle(cubit);
    final target = cubit.state.items.firstWhere(
      (item) => item.sourceId == 'bilibili',
    );

    await cubit.removeItem(target);

    expect(cubit.state.items.map((item) => item.sourceId), ['youtube']);
    final rows = await db.mediaHistoryDao.getHistoryWithMedia();
    expect(rows.map((row) => row.media.sourceId), ['youtube']);

    await cubit.close();
  });

  test(
    'removeItem keeps the pagination cursor aligned for the next page',
    () async {
      // 三页各两条。删掉第一页的一条后，已消费行数必须跟着减，否则下一页的
      // offset 会把紧跟被删行的那条（v2）跳过。
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

      await cubit.removeItem(
        cubit.state.items.firstWhere((item) => item.video.id == 'v1'),
      );
      expect(idsOf(cubit), ['v2']);

      await cubit.loadMore();
      await settle(cubit);
      expect(idsOf(cubit), ['v2', 'v3', 'v4']);

      await cubit.close();
    },
  );

  test('clearAll empties the list and resets pagination', () async {
    for (var i = 1; i <= 3; i++) {
      await addVideo('v$i', sourceId: 'bilibili', minutesAgo: i);
    }

    final cubit = MediaHistoryCubit(
      mediaHistoryDao: db.mediaHistoryDao,
      pageSize: 2,
    );
    await settle(cubit);
    expect(idsOf(cubit), hasLength(2));

    expect(await cubit.clearAll(), isTrue);

    expect(cubit.state.items, isEmpty);
    expect(cubit.state.progressByMedia, isEmpty);
    expect(cubit.state.hasMore, isTrue);
    expect(await db.mediaHistoryDao.getHistoryWithMedia(), isEmpty);

    // 清空后写入新记录，列表应重新从第一页开始显示它。
    await addVideo('v9', sourceId: 'bilibili', minutesAgo: 0);
    final refreshed = await cubit.stream
        .firstWhere((state) => state.items.isNotEmpty)
        .timeout(const Duration(seconds: 10));
    expect(refreshed.items.map((item) => item.video.id), ['v9']);

    await cubit.close();
  });

  test(
    'removeItem surfaces a database failure without dropping the row',
    () async {
      await addVideo('v1', sourceId: 'bilibili', minutesAgo: 1);
      await addVideo('v2', sourceId: 'bilibili', minutesAgo: 2);

      final cubit = MediaHistoryCubit(
        mediaHistoryDao: _FailingDeleteHistoryDao(db),
        pageSize: 10,
      );
      await settle(cubit);
      final target = cubit.state.items.first;

      expect(await cubit.removeItem(target), isFalse);

      expect(cubit.state.error, isNotNull);
      expect(idsOf(cubit), ['v1', 'v2']);

      await cubit.close();
    },
  );
}

/// 删除必然失败的 DAO 包装：只覆盖删除路径，查询仍走真实数据库。
final class _FailingDeleteHistoryDao(super.db) extends MediaHistoryDao {
  @override
  Future<int> deleteHistoryForMediaKey({
    required String sourceId,
    required String originalId,
    String type = Media.typeVideo,
  }) async => throw StateError('delete failed');
}

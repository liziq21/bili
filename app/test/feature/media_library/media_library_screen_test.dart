// ignore_for_file: use_declaring_parameters

import 'package:app/database/app_database.dart';
import 'package:app/database/dao/media_history_dao.dart';
import 'package:app/database/table/media.dart';
import 'package:app/feature/media_library/media_history_cubit.dart';
import 'package:app/feature/media_library/media_library_screen.dart';
import 'package:app/providers/media_sources_provider.dart';
import 'package:data/data.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// `MediaSource` without the service clients behind it: the screen only reads
/// `id` and `name` to label the source badge.
final class _FakeMediaSource({required this.id, required this.name})
    extends MediaSource {
  @override
  final String id;

  @override
  final String name;
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// 测试时钟基准
  ///
  /// 既有测试的「观看于」断言依赖固定锚点，所以默认 2026-01-01。需要验证相对
  /// 时间表述的用例必须传 `anchor: testClock`：从 2026-01-01 往前推算出的
  /// 「5 分钟前」在真实运行时其实是几个月前，相对表述根本不会出现。
  final testClock = DateTime.now();
  Future<void> addVideo(
    String originalId, {
    required String sourceId,
    required int minutesAgo,
    DateTime? anchor,
    int? progressSeconds,
    bool completed = false,
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
          (anchor ?? DateTime(2026)).subtract(Duration(minutes: minutesAgo)),
        ),
        progressSeconds: progressSeconds == null
            ? const Value.absent()
            : Value(BigInt.from(progressSeconds)),
        completed: Value(completed),
      ),
    );
  }

  Future<void> addArticle(String originalId, {required int minutesAgo}) async {
    await db.articleDao.insertArticle((
      MediaCompanion(
        sourceId: const Value('bilibili'),
        originalId: Value(originalId),
        title: Value('Article $originalId'),
        url: Value('https://example.com/$originalId'),
      ),
      ArticleCompanion(content: const Value('body')),
    ));
    final media = await db.articleDao.getArticleMedia('bilibili', originalId);
    await db.mediaHistoryDao.insertMediaHistory(
      MediaHistoryCompanion(
        mediaId: Value(media!.$1.internalId),
        accessedAt: Value(
          DateTime(2026).subtract(Duration(minutes: minutesAgo)),
        ),
      ),
    );
  }

  Future<void> settle(MediaHistoryCubit cubit) async {
    if (!cubit.state.isLoading) return;
    await cubit.stream
        .firstWhere((state) => !state.isLoading)
        .timeout(const Duration(seconds: 10));
  }

  Future<void> pumpLibrary(WidgetTester tester, MediaHistoryCubit cubit) async {
    final tapped = <MediaHistoryItem>[];
    await tester.pumpWidget(
      Provider<MediaSourceCatalog>.value(
        value: MediaSourceCatalog([
          MediaSourceDefinition(
            id: 'bilibili',
            name: 'Bilibili',
            create: () => _FakeMediaSource(id: 'bilibili', name: 'Bilibili'),
          ),
        ]),
        child: BlocProvider<MediaHistoryCubit>.value(
          value: cubit,
          child: MaterialApp(
            home: MediaLibraryScreen(
              onVideoTap: (sourceId, videoId) => tapped.add((
                video: VideoModel(
                  id: videoId,
                  title: 'Video $videoId',
                  url: 'https://example.com/$videoId',
                ),
                sourceId: sourceId,
                viewedAt: DateTime.now(),
              )),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  void registerHistoryCleanup(WidgetTester tester, MediaHistoryCubit cubit) {
    addTearDown(() async {
      // Detach the widget listener before canceling the cubit's bounded Drift
      // stream. This also runs when an assertion fails before the test reaches
      // its normal cleanup path.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      if (!cubit.isClosed) await cubit.close();
    });
  }

  testWidgets('a history row never prints the view count it does not have', (
    tester,
  ) async {
    await addVideo('v1', sourceId: 'bilibili', minutesAgo: 1);

    final cubit = MediaHistoryCubit(
      mediaHistoryDao: db.mediaHistoryDao,
      pageSize: 10,
    );
    registerHistoryCleanup(tester, cubit);
    await settle(cubit);
    await pumpLibrary(tester, cubit);

    expect(find.textContaining('Video v1'), findsOneWidget);
    // `media` has no view count column, so the row subtitle would read
    // "null views" if it interpolated the missing value.
    expect(find.textContaining('null'), findsNothing);
  });

  testWidgets('load more stays available while the list is still empty', (
    tester,
  ) async {
    // More non-video rows than a single load may consume, so the first read ends
    // on the page cap with nothing shown and rows left to read.
    for (var i = 0; i < 24; i++) {
      await addArticle('a$i', minutesAgo: 60 - i);
    }

    final cubit = MediaHistoryCubit(
      mediaHistoryDao: db.mediaHistoryDao,
      pageSize: 2,
    );
    registerHistoryCleanup(tester, cubit);
    await settle(cubit);
    await pumpLibrary(tester, cubit);

    expect(cubit.state.items, isEmpty);
    expect(cubit.state.hasMore, isTrue);

    // The empty-list branch renders no action of its own, so the header's button
    // is the only one: it must not be disabled just because the list is empty.
    final button = tester.widget<TextButton>(find.byType(TextButton));
    expect(button.onPressed, isNotNull);

    // Header load button should expose Semantics and Tooltip for accessibility.
    expect(find.byType(Tooltip), findsWidgets);
    expect(find.byTooltip('Load more history'), findsOneWidget);
  });

  testWidgets(
    'header load button exposes semantics and disabled tooltip when no more items',
    (tester) async {
      final cubit = MediaHistoryCubit(
        mediaHistoryDao: db.mediaHistoryDao,
        pageSize: 10,
      );
      registerHistoryCleanup(tester, cubit);
      await settle(cubit);
      await pumpLibrary(tester, cubit);

      expect(cubit.state.items, isEmpty);
      expect(cubit.state.hasMore, isFalse);

      expect(find.byTooltip('All history loaded'), findsOneWidget);
    },
  );

  testWidgets('labels each row with its source and when it was watched', (
    tester,
  ) async {
    // Two sources watched at different times: the row must say which service the
    // entry came from and how long ago, otherwise a cross-source history reads
    // as one undifferentiated list.
    await addVideo(
      'v1',
      sourceId: 'bilibili',
      minutesAgo: 5,
      anchor: testClock,
    );
    await addVideo(
      'v2',
      sourceId: 'bilibili',
      minutesAgo: 60 * 5,
      anchor: testClock,
    );
    // Past 24 hours the hour bucket would read oddly ("30 小时前" for yesterday
    // afternoon), so the day bucket takes over.
    await addVideo(
      'v3',
      sourceId: 'bilibili',
      minutesAgo: 60 * 30,
      anchor: testClock,
    );

    final cubit = MediaHistoryCubit(
      mediaHistoryDao: db.mediaHistoryDao,
      pageSize: 10,
    );
    registerHistoryCleanup(tester, cubit);
    await settle(cubit);
    await pumpLibrary(tester, cubit);

    // The row subtitle leads with the source display name rather than the raw
    // id: the id is an internal identifier and would mean nothing to a reader.
    expect(find.text('Bilibili - Just now'), findsOneWidget);
    expect(find.text('Bilibili - Earlier today'), findsOneWidget);
    expect(find.text('Bilibili - This week'), findsOneWidget);
    expect(find.textContaining('bilibili'), findsNothing);
  });

  testWidgets('falls back to a date once a row is older than a week', (
    tester,
  ) async {
    // `addVideo` anchors the access time to DateTime(2026) (1 Jan), months
    // before the test clock, so the row must render a date rather than a
    // relative phrase. The exact date is not pinned: it crosses a year boundary
    // depending on when the suite runs, so asserting it would make the test fail
    // on a clock change rather than on a real regression.
    await addVideo('v1', sourceId: 'bilibili', minutesAgo: 60 * 24 * 30);

    final cubit = MediaHistoryCubit(
      mediaHistoryDao: db.mediaHistoryDao,
      pageSize: 10,
    );
    registerHistoryCleanup(tester, cubit);
    await settle(cubit);
    await pumpLibrary(tester, cubit);

    expect(find.textContaining('ago'), findsNothing);
    expect(find.textContaining('today'), findsNothing);
    // MM-DD inside one year, YYYY-MM-DD across one.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            RegExp(r'^Bilibili - (\d{4}-)?\d{2}-\d{2}$')
                .hasMatch(widget.data ?? ''),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows saved playback progress in the history subtitle', (
    tester,
  ) async {
    await addVideo(
      'v1',
      sourceId: 'bilibili',
      minutesAgo: 5,
      anchor: testClock,
      progressSeconds: 61,
    );

    final cubit = MediaHistoryCubit(
      mediaHistoryDao: db.mediaHistoryDao,
      pageSize: 10,
    );
    registerHistoryCleanup(tester, cubit);
    await settle(cubit);
    await pumpLibrary(tester, cubit);

    expect(find.text('Bilibili - Just now'), findsOneWidget);
  });

  testWidgets('long-press deletes the row after confirmation', (tester) async {
    await addVideo('v1', sourceId: 'bilibili', minutesAgo: 1);
    await addVideo('v2', sourceId: 'bilibili', minutesAgo: 2);

    final cubit = MediaHistoryCubit(
      mediaHistoryDao: db.mediaHistoryDao,
      pageSize: 10,
    );
    registerHistoryCleanup(tester, cubit);
    await settle(cubit);
    await pumpLibrary(tester, cubit);

    await tester.longPress(find.textContaining('Video v1'));
    await tester.pumpAndSettle();
    expect(find.text('Delete "Video v1" from history?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    // 删除先写库再发提示，库操作是真实异步 I/O：假时钟推不动它，必须让出
    // 真实时间；随后只 pump 一帧断言提示，pumpAndSettle 会把 SnackBar 的
    // 自动消失计时一起走完。
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(find.text('Removed from history'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.textContaining('Video v1'), findsNothing);
    expect(find.textContaining('Video v2'), findsOneWidget);
    // 确认框只是界面动作，库里的行必须真的没了，否则重进页面又出现。
    final rows = await db.mediaHistoryDao.getHistoryWithMedia();
    expect(rows.map((row) => row.media.originalId), ['v2']);
  });

  testWidgets('cancelling the delete dialog keeps the row', (tester) async {
    await addVideo('v1', sourceId: 'bilibili', minutesAgo: 1);

    final cubit = MediaHistoryCubit(
      mediaHistoryDao: db.mediaHistoryDao,
      pageSize: 10,
    );
    registerHistoryCleanup(tester, cubit);
    await settle(cubit);
    await pumpLibrary(tester, cubit);

    await tester.longPress(find.textContaining('Video v1'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Video v1'), findsOneWidget);
    expect(await db.mediaHistoryDao.getHistoryWithMedia(), hasLength(1));
  });

  testWidgets('the header clear action empties the list after confirmation', (
    tester,
  ) async {
    await addVideo('v1', sourceId: 'bilibili', minutesAgo: 1);
    await addVideo('v2', sourceId: 'bilibili', minutesAgo: 2);

    final cubit = MediaHistoryCubit(
      mediaHistoryDao: db.mediaHistoryDao,
      pageSize: 10,
    );
    registerHistoryCleanup(tester, cubit);
    await settle(cubit);
    await pumpLibrary(tester, cubit);

    await tester.tap(find.byTooltip('Clear all watch history'));
    await tester.pumpAndSettle();
    expect(find.text('Clear all watch history?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    // 同上：清空同样先写库，真实 I/O 需要让出真实时间。
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(find.text('Watch history cleared'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(cubit.state.items, isEmpty);
    expect(find.text('No watch history yet'), findsOneWidget);
    expect(await db.mediaHistoryDao.getHistoryWithMedia(), isEmpty);
  });

  testWidgets('a failed delete shows no success snack bar', (tester) async {
    await addVideo('v1', sourceId: 'bilibili', minutesAgo: 1);

    final cubit = MediaHistoryCubit(
      mediaHistoryDao: _FailingDeleteHistoryDao(db),
      pageSize: 10,
    );
    registerHistoryCleanup(tester, cubit);
    await settle(cubit);
    await pumpLibrary(tester, cubit);

    await tester.longPress(find.textContaining('Video v1'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    // 先等对话框退场，否则它的标题里也含「Video v1」，与列表行的断言撞在一起。
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    // 写库失败时行还在树上，提示不能说「已移除」——那与用户看到的画面矛盾。
    expect(find.text('Removed from history'), findsNothing);
    expect(find.textContaining('Video v1'), findsOneWidget);
    expect(cubit.state.error, isNotNull);
  });

  testWidgets('the clear action is disabled while the list is empty', (
    tester,
  ) async {
    final cubit = MediaHistoryCubit(
      mediaHistoryDao: db.mediaHistoryDao,
      pageSize: 10,
    );
    registerHistoryCleanup(tester, cubit);
    await settle(cubit);
    await pumpLibrary(tester, cubit);

    // 空列表上清空没有意义；常驻但禁用，比忽隐忽现更容易预期。
    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.delete_sweep_outlined),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('tapping a row hands over the source that row was loaded from', (
    tester,
  ) async {
    await addVideo('v1', sourceId: 'bilibili', minutesAgo: 1);

    final cubit = MediaHistoryCubit(
      mediaHistoryDao: db.mediaHistoryDao,
      pageSize: 10,
    );
    registerHistoryCleanup(tester, cubit);
    await settle(cubit);

    final tapped = <MediaHistoryItem>[];
    await tester.pumpWidget(
      Provider<MediaSourceCatalog>.value(
        value: MediaSourceCatalog([
          MediaSourceDefinition(
            id: 'bilibili',
            name: 'Bilibili',
            create: () => _FakeMediaSource(id: 'bilibili', name: 'Bilibili'),
          ),
        ]),
        child: BlocProvider<MediaHistoryCubit>.value(
          value: cubit,
          child: MaterialApp(
            home: MediaLibraryScreen(
              onVideoTap: (sourceId, videoId) => tapped.add((
                video: VideoModel(
                  id: videoId,
                  title: 'Video $videoId',
                  url: 'https://example.com/$videoId',
                ),
                sourceId: sourceId,
                viewedAt: DateTime.now(),
              )),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.textContaining('Video v1'));
    await tester.pump();

    expect(tapped, hasLength(1));
    expect(tapped.single.video.id, 'v1');
    expect(tapped.single.sourceId, 'bilibili');
  });
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

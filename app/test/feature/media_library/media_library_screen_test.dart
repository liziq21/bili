// ignore_for_file: use_declaring_parameters

import 'package:app/database/app_database.dart';
import 'package:app/feature/media_library/media_history_cubit.dart';
import 'package:app/feature/media_library/media_library_screen.dart';
import 'package:data/data.dart';
import 'package:drift/drift.dart' hide isNotNull;
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

  Future<void> pumpLibrary(
    WidgetTester tester,
    MediaHistoryCubit cubit,
  ) async {
    final tapped = <MediaHistoryItem>[];
    await tester.pumpWidget(
      Provider<List<MediaSource>>.value(
        value: [_FakeMediaSource(id: 'bilibili', name: 'Bilibili')],
        child: BlocProvider<MediaHistoryCubit>.value(
          value: cubit,
          child: MaterialApp(
            home: MediaLibraryScreen(onVideoTap: tapped.add),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a history card never prints the view count it does not have', (
    tester,
  ) async {
    await addVideo('v1', sourceId: 'bilibili', minutesAgo: 1);

    final cubit = MediaHistoryCubit(
      mediaHistoryDao: db.mediaHistoryDao,
      pageSize: 10,
    );
    await settle(cubit);
    await pumpLibrary(tester, cubit);

    expect(find.textContaining('Video v1'), findsOneWidget);
    // `media` has no view count column, so the card subtitle would read
    // "null views" if it interpolated the missing value.
    expect(find.textContaining('null'), findsNothing);

    await cubit.close();
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
    await settle(cubit);
    await pumpLibrary(tester, cubit);

    expect(cubit.state.items, isEmpty);
    expect(cubit.state.hasMore, isTrue);

    // The empty-list branch renders no action of its own, so the header's button
    // is the only one: it must not be disabled just because the list is empty.
    final button = tester.widget<TextButton>(find.byType(TextButton));
    expect(button.onPressed, isNotNull);

    await cubit.close();
  });

  testWidgets('tapping a card hands over the source that card was loaded from', (
    tester,
  ) async {
    await addVideo('v1', sourceId: 'bilibili', minutesAgo: 1);

    final cubit = MediaHistoryCubit(
      mediaHistoryDao: db.mediaHistoryDao,
      pageSize: 10,
    );
    await settle(cubit);

    final tapped = <MediaHistoryItem>[];
    await tester.pumpWidget(
      Provider<List<MediaSource>>.value(
        value: [_FakeMediaSource(id: 'bilibili', name: 'Bilibili')],
        child: BlocProvider<MediaHistoryCubit>.value(
          value: cubit,
          child: MaterialApp(
            home: MediaLibraryScreen(onVideoTap: tapped.add),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Video v1'));
    await tester.pumpAndSettle();

    expect(tapped, hasLength(1));
    expect(tapped.single.video.id, 'v1');
    expect(tapped.single.sourceId, 'bilibili');

    await cubit.close();
  });
}

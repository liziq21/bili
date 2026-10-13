// ignore_for_file: annotate_overrides

import 'package:app/data/repository/local_library_repository.dart';
import 'package:app/database/app_database.dart';
import 'package:app/feature/media_library/local_library_screen.dart';
import 'package:app/providers/media_sources_provider.dart';
import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class const _FakeSource({required final String id, required final String name})
    extends MediaSource;

class _FailOnceBookmarkRepository({required super.dao})
    extends LocalLibraryRepository {
  var failFirstWatch = true;

  @override
  Stream<List<LocalBookmarkEntity>> watchBookmarks() {
    if (failFirstWatch) {
      failFirstWatch = false;
      return Stream<List<LocalBookmarkEntity>>.error(
        StateError('first bookmark watch failed'),
      );
    }
    return super.watchBookmarks();
  }
}

void main() {
  late AppDatabase database;
  late LocalLibraryRepository repository;

  final catalog = MediaSourceCatalog([
    const MediaSourceDefinition(
      id: 'bilibili',
      name: 'Bilibili',
      create: _bilibili,
    ),
    const MediaSourceDefinition(
      id: 'youtube',
      name: 'YouTube',
      create: _youtube,
    ),
  ]);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = LocalLibraryRepository(dao: database.localLibraryDao);
  });

  tearDown(() => database.close());

  void testLibraryWidgets(
    String description,
    Future<void> Function(WidgetTester tester) body,
  ) {
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        // Drift defers removal of an unused query stream with Timer.run().
        // Unmount while the test's fake-async zone is still active, then pump
        // that timer before tearDown closes the database.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });
  }

  Widget app(Widget child, {LocalLibraryRepository? value}) => MaterialApp(
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('en')],
    // Keep both providers below Navigator. The source picker must capture its
    // catalog before showDialog creates a route above this subtree.
    home: RepositoryProvider<LocalLibraryRepository>.value(
      value: value ?? repository,
      child: Provider<MediaSourceCatalog>.value(value: catalog, child: child),
    ),
  );

  LocalLibraryScreen screen({
    void Function(String sourceId, String videoId)? onVideoTap,
    void Function(String sourceId, String creatorId)? onCreatorTap,
  }) => LocalLibraryScreen(
    history: const SizedBox.shrink(),
    onVideoTap: onVideoTap ?? (_, _) {},
    onCreatorTap: onCreatorTap ?? (_, _) {},
  );

  Future<void> pumpLibrary(WidgetTester tester) async {
    for (var index = 0; index < 8; index++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> pumpRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await pumpLibrary(tester);
  }

  Future<void> openPlaylistMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip('播放列表操作'));
    await pumpRoute(tester);
  }

  Future<void> openPlaylistItemMenu(WidgetTester tester, int index) async {
    await tester.tap(find.byTooltip('条目操作').at(index));
    await pumpRoute(tester);
  }

  testLibraryWidgets(
    'creates and deletes a playlist through the real database',
    (tester) async {
      await tester.pumpWidget(app(screen()));
      await pumpLibrary(tester);
      await openTab(tester, '播放列表');

      await tester.tap(find.text('新建播放列表'));
      await pumpRoute(tester);
      await tester.enterText(find.byType(TextField), 'Watch later');
      await tester.tap(find.text('创建'));
      await pumpLibrary(tester);

      expect(find.text('Watch later'), findsOneWidget);
      expect(await repository.getPlaylists(), hasLength(1));

      await openPlaylistMenu(tester);
      await tester.tap(find.text('删除播放列表'));
      await pumpRoute(tester);
      await tester.tap(find.text('删除').last);
      await pumpLibrary(tester);

      expect(find.text('Watch later'), findsNothing);
      expect(await repository.getPlaylists(), isEmpty);
    },
  );

  testLibraryWidgets('removes only one duplicate playlist occurrence', (
    tester,
  ) async {
    final playlistId = await repository.createPlaylist('bilibili', 'Queue');
    const video = VideoModel(
      id: 'same',
      title: 'Repeated video',
      url: 'https://example.com/same',
    );
    await repository.addToPlaylist(
      playlistId: playlistId,
      sourceId: 'bilibili',
      video: video,
    );
    await repository.addToPlaylist(
      playlistId: playlistId,
      sourceId: 'bilibili',
      video: video,
    );

    await tester.pumpWidget(app(screen()));
    await pumpLibrary(tester);
    await openTab(tester, '播放列表');
    expect(find.text('Repeated video'), findsNWidgets(2));

    await openPlaylistItemMenu(tester, 0);
    await tester.tap(find.text('移除这一次'));
    await pumpLibrary(tester);

    expect(find.text('Repeated video'), findsOneWidget);
    expect(await repository.getPlaylistItems(playlistId), hasLength(1));
  });

  testLibraryWidgets('reorders playlist items from the item menu', (
    tester,
  ) async {
    final playlistId = await repository.createPlaylist('bilibili', 'Queue');
    for (final video in const [
      VideoModel(id: 'a', title: 'First', url: 'https://example.com/a'),
      VideoModel(id: 'b', title: 'Second', url: 'https://example.com/b'),
    ]) {
      await repository.addToPlaylist(
        playlistId: playlistId,
        sourceId: 'bilibili',
        video: video,
      );
    }

    await tester.pumpWidget(app(screen()));
    await pumpLibrary(tester);
    await openTab(tester, '播放列表');
    expect(
      tester.getTopLeft(find.text('First')).dy,
      lessThan(tester.getTopLeft(find.text('Second')).dy),
    );

    await openPlaylistItemMenu(tester, 1);
    await tester.tap(find.text('上移'));
    await pumpLibrary(tester);

    expect(
      tester.getTopLeft(find.text('Second')).dy,
      lessThan(tester.getTopLeft(find.text('First')).dy),
    );
    final items = await repository.getPlaylistItems(playlistId);
    expect(items.map((item) => item.originalId), ['b', 'a']);
  });

  testLibraryWidgets('batch-adds only same-source bookmarks to a playlist', (
    tester,
  ) async {
    final playlistId = await repository.createPlaylist('bilibili', 'Queue');
    for (final video in const [
      VideoModel(id: 'a', title: 'Saved A', url: 'https://example.com/a'),
      VideoModel(id: 'b', title: 'Saved B', url: 'https://example.com/b'),
    ]) {
      await repository.setBookmark(
        sourceId: 'bilibili',
        video: video,
        bookmarked: true,
      );
    }
    await repository.setBookmark(
      sourceId: 'youtube',
      video: const VideoModel(
        id: 'y',
        title: 'Other source',
        url: 'https://example.com/y',
      ),
      bookmarked: true,
    );

    await tester.pumpWidget(app(screen()));
    await pumpLibrary(tester);
    await openTab(tester, '播放列表');
    await openPlaylistMenu(tester);
    await tester.tap(find.text('添加收藏'));
    await pumpRoute(tester);

    expect(find.text('Saved A'), findsOneWidget);
    expect(find.text('Saved B'), findsOneWidget);
    expect(find.text('Other source'), findsNothing);
    final choices = find.byType(CheckboxListTile);
    expect(choices, findsNWidgets(2));
    await tester.tap(choices.at(0));
    await tester.tap(choices.at(1));
    await tester.tap(find.text('添加'));
    await pumpLibrary(tester);

    final items = await repository.getPlaylistItems(playlistId);
    expect(
      items.map((item) => item.originalId),
      containsAll(<String>['a', 'b']),
    );
    expect(items.every((item) => item.sourceId == 'bilibili'), isTrue);
  });

  testLibraryWidgets(
    'groups subscriptions, filters source, unsubscribes, and calls back',
    (tester) async {
      await repository.setSubscription(
        sourceId: 'bilibili',
        creator: const CreatorProfile(id: 'b1', name: 'Bili creator'),
        subscribed: true,
      );
      await repository.setSubscriptionGroup('bilibili', 'b1', '');
      await repository.setSubscription(
        sourceId: 'youtube',
        creator: const CreatorProfile(id: 'y1', name: 'YouTube creator'),
        subscribed: true,
      );
      await repository.setSubscriptionGroup('youtube', 'y1', '未分组');
      final creatorTaps = <(String sourceId, String creatorId)>[];

      await tester.pumpWidget(
        app(
          screen(
            onCreatorTap: (sourceId, creatorId) =>
                creatorTaps.add((sourceId, creatorId)),
          ),
        ),
      );
      await pumpLibrary(tester);
      await openTab(tester, '订阅');
      expect(find.text('未分组'), findsNWidgets(2));

      await tester.tap(find.text('筛选'));
      await pumpRoute(tester);
      await tester.tap(find.text('Bilibili').last);
      await pumpLibrary(tester);
      expect(find.text('Bili creator'), findsOneWidget);
      expect(find.text('YouTube creator'), findsNothing);

      await tester.tap(find.text('Bili creator'));
      expect(creatorTaps, [('bilibili', 'b1')]);

      await tester.tap(find.byTooltip('订阅操作'));
      await pumpRoute(tester);
      await tester.tap(find.text('设置分组'));
      await pumpRoute(tester);
      await tester.enterText(find.byType(TextField), 'Favorites');
      await tester.tap(find.text('保存'));
      await pumpLibrary(tester);
      expect(find.text('Favorites'), findsOneWidget);

      await tester.tap(find.byTooltip('订阅操作'));
      await pumpRoute(tester);
      await tester.tap(find.text('取消订阅'));
      await pumpLibrary(tester);
      expect(find.text('Bili creator'), findsNothing);
      expect(await repository.getSubscriptions(), hasLength(1));
    },
  );

  testLibraryWidgets(
    'does not show the source filter for parent-owned history',
    (tester) async {
      await tester.pumpWidget(app(screen()));
      await pumpLibrary(tester);
      expect(find.text('筛选'), findsNothing);
      await openTab(tester, '收藏');
      expect(find.text('筛选'), findsOneWidget);
    },
  );

  testLibraryWidgets('recreates a failed local stream when retrying', (
    tester,
  ) async {
    final failingRepository = _FailOnceBookmarkRepository(
      dao: database.localLibraryDao,
    );
    await tester.pumpWidget(app(screen(), value: failingRepository));
    await pumpLibrary(tester);
    await openTab(tester, '收藏');
    expect(find.text('收藏加载失败'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await pumpLibrary(tester);
    expect(find.text('还没有收藏'), findsOneWidget);
  });
}

MediaSource _bilibili() => const _FakeSource(id: 'bilibili', name: 'Bilibili');

MediaSource _youtube() => const _FakeSource(id: 'youtube', name: 'YouTube');

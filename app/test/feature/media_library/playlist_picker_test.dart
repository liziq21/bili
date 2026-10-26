import 'package:app/data/repository/local_library_repository.dart';
import 'package:app/database/app_database.dart';
import 'package:app/feature/media_library/playlist_picker.dart';
import 'package:data/data.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FailOnceRepository({required super.dao}) extends LocalLibraryRepository {
  var failFirstAppend = true;
  var failFirstWatch = true;

  @override
  Stream<List<LocalPlaylistEntity>> watchPlaylists() {
    if (failFirstWatch) {
      failFirstWatch = false;
      return Stream<List<LocalPlaylistEntity>>.error(
        StateError('first watch failed'),
      );
    }
    return super.watchPlaylists();
  }

  @override
  Future<void> addToPlaylist({
    required int playlistId,
    required String sourceId,
    required VideoModel video,
  }) {
    if (failFirstAppend) {
      failFirstAppend = false;
      return Future<void>.error(StateError('first append failed'));
    }
    return super.addToPlaylist(
      playlistId: playlistId,
      sourceId: sourceId,
      video: video,
    );
  }
}

void main() {
  late AppDatabase database;
  late LocalLibraryRepository repository;

  setUp(() {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repository = LocalLibraryRepository(dao: database.localLibraryDao);
  });

  tearDown(() => database.close());

  void testPickerWidgets(
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

  Widget app(LocalLibraryRepository value) => MaterialApp(
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('en')],
    home: RepositoryProvider<LocalLibraryRepository>.value(
      value: value,
      child: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () => showLocalPlaylistPicker(
              context,
              sourceId: 'bilibili',
              video: const VideoModel(
                id: 'video-1',
                title: 'Saved video',
                url: 'https://example.com/video-1',
              ),
            ),
            child: const Text('选择列表'),
          ),
        ),
      ),
    ),
  );

  Future<void> pumpDb(WidgetTester tester) async {
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

  testPickerWidgets('creates a playlist and appends the video', (tester) async {
    await tester.pumpWidget(app(repository));
    await pumpDb(tester);

    await tester.tap(find.text('选择列表'));
    await pumpRoute(tester);
    await tester.tap(find.text('新建播放列表'));
    await pumpRoute(tester);
    await tester.enterText(find.byType(TextField), 'Watch later');
    await tester.tap(find.text('创建'));
    await pumpDb(tester);

    final playlists = await repository.getPlaylists();
    expect(playlists, hasLength(1));
    expect(playlists.single.name, 'Watch later');
    final items = await repository.getPlaylistItems(
      playlists.single.internalId,
    );
    expect(items, hasLength(1));
    expect(items.single.originalId, 'video-1');
  });

  testPickerWidgets(
    'retries a failed stream and a failed append without closing',
    (tester) async {
      final failingRepository = _FailOnceRepository(
        dao: database.localLibraryDao,
      );
      final playlistId = await failingRepository.createPlaylist(
        'bilibili',
        'Watch later',
      );

      await tester.pumpWidget(app(failingRepository));
      await pumpDb(tester);
      await tester.tap(find.text('选择列表'));
      await pumpRoute(tester);

      expect(find.text('播放列表加载失败'), findsOneWidget);
      await tester.tap(find.text('重试'));
      await pumpDb(tester);
      expect(find.text('Watch later'), findsOneWidget);

      expect(find.byTooltip('添加到 Watch later'), findsOneWidget);
      expect(find.bySemanticsLabel('添加到播放列表 Watch later'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == '添加到播放列表 Watch later' &&
              widget.excludeSemantics == true,
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Watch later'));
      await pumpDb(tester);
      expect(find.textContaining('添加失败'), findsOneWidget);
      expect(find.text('添加到播放列表'), findsOneWidget);

      await tester.tap(find.text('Watch later'));
      await pumpDb(tester);
      expect(find.text('添加到播放列表'), findsNothing);
      expect(
        await failingRepository.getPlaylistItems(playlistId),
        hasLength(1),
      );
    },
  );
}

import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/database/app_database.dart';
import 'package:app/database/dao/media_history_dao.dart';
import 'package:app/database/table/media.dart';
import 'package:app/datastore/media_history_settings.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/video/common_widgets/playback_queue_sheet.dart';
import 'package:app/feature/video/common_widgets/video_comments_view.dart';
import 'package:app/feature/video/common_widgets/video_info_view.dart';
import 'package:app/feature/video/common_widgets/video_player.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:app/feature/video/video_screen.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:data/data.dart';
import 'package:drift/native.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:app/design/design.dart';

import 'fake_platform_player.dart';

void main() {
  testWidgets('video detail page exposes a page back button', (tester) async {
    var backPressed = false;

    // 设置测试视口大小，避免内容区在极小约束下溢出。
    // 必须在 pumpWidget 之前设置 tester.view.physicalSize，
    // 否则 MaterialApp 会捕获默认的 320x30 视口尺寸。
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      Provider<MediaSource>.value(
        value: const _TestMediaSource(),
        child: RepositoryProvider<VideoDetailRepository>.value(
          value: const _FailingVideoDetailRepository(),
          child: MaterialApp(
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: VideoScreen(onBackClick: () => backPressed = true),
          ),
        ),
      ),
    );
    await tester.pump();

    // 返回按钮叠在播放器上，不再占一整条 AppBar 的高度。
    expect(find.byType(AppBar), findsNothing);
    expect(find.byIcon(AppIcons.back), findsOneWidget);
    final playerRect = tester.getRect(find.byType(VideoPlayer));
    final backRect = tester.getRect(find.byIcon(AppIcons.back));
    expect(playerRect.contains(backRect.center), isTrue);

    await tester.tap(find.byIcon(AppIcons.back));
    expect(backPressed, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  group('responsive layout', () {
    /// 按指定视口尺寸 pump 整个页面，并保证测试结束时卸载页面释放播放器。
    Future<void> pumpAt(
      WidgetTester tester,
      Size size, {
      VoidCallback? onBack,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        Provider<MediaSource>.value(
          value: const _TestMediaSource(),
          child: RepositoryProvider<VideoDetailRepository>.value(
            value: const _FailingVideoDetailRepository(),
            child: MaterialApp(
              localizationsDelegates: const [
                ...AppLocalizations.localizationsDelegates,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('zh'),
              home: VideoScreen(onBackClick: onBack ?? () {}),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    testWidgets('compact width keeps the tabbed layout', (tester) async {
      await pumpAt(tester, const Size(400, 900));

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(PlaybackQueueSheet), findsNothing);
      expect(find.byIcon(AppIcons.back), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('comments tab label carries no hardcoded sample count', (
      tester,
    ) async {
      await pumpAt(tester, const Size(360, 640));

      // #663：评论区 Tab 曾是写死的「评论区 (1,429)」，与真实评论数无关，
      // 且在 360 宽被截成「评论区 (1,42」。标签不应带任何数字。
      final tabLabels = tester
          .widgetList<Tab>(find.byType(Tab))
          .map((tab) => tab.text)
          .toList();
      expect(tabLabels, contains('评论区'));
      expect(
        tabLabels.every((label) => !(label ?? '').contains(RegExp(r'\d'))),
        isTrue,
        reason: 'tab labels must not embed a sample count: $tabLabels',
      );
      expect(tester.takeException(), isNull);

      await unmount(tester);
    });

    testWidgets('foldable landscape shows info and comments side by side', (
      tester,
    ) async {
      // 折叠屏展开态横屏：宽度足以双栏，但塞不下 320dp 的队列侧栏。
      await pumpAt(tester, const Size(841, 673));

      expect(find.byType(TabBar), findsNothing);
      expect(find.byType(VideoInfoView), findsOneWidget);
      expect(find.byType(VideoCommentsView), findsOneWidget);
      expect(find.byType(PlaybackQueueSheet), findsNothing);
      expect(tester.takeException(), isNull);

      await unmount(tester);
    });

    testWidgets('expanded width restores the persistent queue pane', (
      tester,
    ) async {
      await pumpAt(tester, const Size(1440, 900));

      expect(find.byType(TabBar), findsNothing);
      expect(find.byType(VideoInfoView), findsOneWidget);
      expect(find.byType(VideoCommentsView), findsOneWidget);
      expect(find.byType(PlaybackQueueSheet), findsOneWidget);
      // 内嵌侧栏不是模态弹层，不应出现会 pop 掉视频路由的关闭按钮。
      expect(find.byIcon(AppIcons.close), findsNothing);

      await unmount(tester);
    });

    testWidgets('expanded width puts the queue pane beside the player', (
      tester,
    ) async {
      await pumpAt(tester, const Size(1440, 900));

      // 队列侧栏与播放器并列，播放器与详情/评论同处左侧内容区：视频不再按
      // 整窗宽度居中后被侧栏盖住。
      final playerRect = tester.getRect(find.byType(VideoPlayer));
      final queueRect = tester.getRect(find.byType(PlaybackQueueSheet));
      expect(playerRect.right, lessThanOrEqualTo(queueRect.left));
      expect(queueRect.width, closeTo(320, 1));
      expect(tester.takeException(), isNull);

      await unmount(tester);
    });

    testWidgets('short landscape caps the player instead of overflowing', (
      tester,
    ) async {
      await pumpAt(tester, const Size(800, 360));

      expect(find.byType(VideoInfoView), findsOneWidget);
      expect(tester.getSize(find.byType(VideoInfoView)).height, greaterThan(0));
      expect(tester.takeException(), isNull);

      await unmount(tester);
    });
  });

  group('resume from watch history', () {
    late AppDatabase db;
    late PreferencesDataSource preferences;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      preferences = PreferencesDataSource(
        sharedPreferences: SharedPreferencesAsync(),
      );
    });

    tearDown(() async {
      preferences.dispose();
      await db.close();
    });

    /// 记录一条历史进度，模拟用户上次看到 [seconds] 秒。
    Future<void> saveHistoryProgress(
      String videoId,
      int seconds, {
      String sourceId = 'test',
    }) async {
      final mediaId = await db.mediaHistoryDao.getOrCreateMediaId(
        sourceId,
        videoId,
        Media.typeVideo,
      );
      await db.mediaHistoryDao.saveProgress(mediaId, seconds);
    }

    /// pump 页面：注入假播放器，画面用空盒子，只关心起播后的 seek。
    Future<void> pumpPage(
      WidgetTester tester, {
      required MediaPlaybackController controller,
      String videoId = 'BV1resume',
      VideoDetailRepository repository = const _ReadyStreamRepository(),
    }) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        Provider<MediaSource>.value(
          value: const _TestMediaSource(),
          child: RepositoryProvider<VideoDetailRepository>.value(
            value: repository,
            child: RepositoryProvider<AppDatabase>.value(
              value: db,
              child: RepositoryProvider<MediaHistoryDao>.value(
                value: db.mediaHistoryDao,
                child: RepositoryProvider<PreferencesDataSource>.value(
                  value: preferences,
                  child: MaterialApp(
                    localizationsDelegates: const [
                      ...AppLocalizations.localizationsDelegates,
                      ...GlobalMaterialLocalizations.delegates,
                    ],
                    supportedLocales: AppLocalizations.supportedLocales,
                    locale: const Locale('zh'),
                    home: VideoScreen(
                      videoId: videoId,
                      playbackController: controller,
                      surfaceBuilder: (_) => const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      // 进度读取是异步的：先让 FutureBuilder 落地，再让画面起播。
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('seeks to the saved second instead of starting over', (
      tester,
    ) async {
      await saveHistoryProgress('BV1resume', 42);
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);

      await pumpPage(tester, controller: controller);

      expect(fake.openCalls, hasLength(1));
      expect(fake.seekCalls, hasLength(1));
      expect(fake.seekCalls.single, const Duration(seconds: 42));
      // seek 只该发生一次：续播位置用完即清零，重建不该再跳。
      expect(controller.restorePositionSeconds, 0);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      addTearDown(controller.dispose);
    });

    testWidgets('records title and cover once the detail arrives', (
      tester,
    ) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);

      await pumpPage(
        tester,
        controller: controller,
        repository: const _TitledVideoRepository(),
      );
      // 详情到达后写库是异步的：让真实 I/O 落地，再断言。
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();

      final rows = await tester.runAsync(
        () => db.mediaHistoryDao.getHistoryWithMedia(),
      );
      expect(rows, hasLength(1));
      expect(rows!.single.media.title, 'A real title');
      expect(rows.single.media.thumbnailUrl, 'https://example.com/cover.jpg');
      expect(rows.single.media.creatorProfileName, 'UP');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      addTearDown(controller.dispose);
    });

    testWidgets('a new video id loads that video, not the previous one', (
      tester,
    ) async {
      final repository = _RecordingDetailRepository();
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);

      await pumpPage(
        tester,
        controller: controller,
        videoId: 'BV1first',
        repository: repository,
      );
      // 同一个 bloc provider 仍在树上时换 id。
      await pumpPage(
        tester,
        controller: controller,
        videoId: 'BV1second',
        repository: repository,
      );
      await tester.pump();

      expect(repository.detailIds, contains('BV1second'));
      expect(repository.streamIds, contains('BV1second'));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      addTearDown(controller.dispose);
    });

    testWidgets('starts from the beginning when nothing was saved', (
      tester,
    ) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);

      await pumpPage(tester, controller: controller);

      expect(fake.openCalls, hasLength(1));
      expect(fake.seekCalls, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      addTearDown(controller.dispose);
    });

    testWidgets('ignores the saved second when resuming is switched off', (
      tester,
    ) async {
      await saveHistoryProgress('BV1resume', 42);
      await const MediaHistorySettings(resumePlayback: false).save(preferences);
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);

      await pumpPage(tester, controller: controller);

      expect(fake.openCalls, hasLength(1));
      expect(fake.seekCalls, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      addTearDown(controller.dispose);
    });

    testWidgets('only reads the progress of the video being opened', (
      tester,
    ) async {
      await saveHistoryProgress('BV1other', 99);
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);

      await pumpPage(tester, controller: controller);

      expect(fake.seekCalls, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      addTearDown(controller.dispose);
    });
  });
}

/// 立即返回可播流的仓库：让画面本体渲染出来，播放器才有东西可 seek。
class const _ReadyStreamRepository() implements VideoDetailRepository {
  @override
  Future<Result<VideoDetail, Exception>> getVideoDetail(String id) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool, Exception>> toggleLike(String id, bool isLiked) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool, Exception>> toggleFavorite(
    String id,
    bool isFavorited,
  ) async => Result.error(Exception('unused'));

  @override
  Future<Result<bool, Exception>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => Result.error(Exception('unused'));

  @override
  Future<Result<MediaStream, Exception>> getMediaStream(
    String id, {
    int? preferHeight,
    int? preferStreamId,
  }) async => Result.success(
    MediaStream(videoUrl: 'https://example.com/$id.m4s', height: 1080),
  );
}

class const _TitledVideoRepository() implements VideoDetailRepository {
  @override
  Future<Result<VideoDetail, Exception>> getVideoDetail(String id) async =>
      Result.success(
        VideoDetail(
          video: VideoModel(
            id: id,
            title: 'A real title',
            url: 'https://www.bilibili.com/video/$id',
            thumbnailUrl: 'https://example.com/cover.jpg',
            creatorProfileName: 'UP',
            creatorProfileId: '42',
          ),
        ),
      );

  @override
  Future<Result<bool, Exception>> toggleLike(String id, bool isLiked) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool, Exception>> toggleFavorite(
    String id,
    bool isFavorited,
  ) async => Result.error(Exception('unused'));

  @override
  Future<Result<bool, Exception>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => Result.error(Exception('unused'));

  @override
  Future<Result<MediaStream, Exception>> getMediaStream(
    String id, {
    int? preferHeight,
    int? preferStreamId,
  }) async => Result.success(
    MediaStream(videoUrl: 'https://example.com/$id.m4s', height: 1080),
  );
}

/// 记录详情与播放地址请求的 id，用于断言换视频后重新派发。
class _RecordingDetailRepository() implements VideoDetailRepository {
  final detailIds = <String>[];
  final streamIds = <String>[];

  @override
  Future<Result<VideoDetail, Exception>> getVideoDetail(String id) async {
    detailIds.add(id);
    return Result.success(
      VideoDetail(
        video: VideoModel(
          id: id,
          title: 'Title $id',
          url: 'https://example.com/$id',
        ),
      ),
    );
  }

  @override
  Future<Result<MediaStream, Exception>> getMediaStream(
    String id, {
    int? preferHeight,
    int? preferStreamId,
  }) async {
    streamIds.add(id);
    return Result.success(MediaStream(videoUrl: 'https://example.com/$id.m4s'));
  }

  @override
  Future<Result<bool, Exception>> toggleLike(String id, bool isLiked) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool, Exception>> toggleFavorite(
    String id,
    bool isFavorited,
  ) async => Result.error(Exception('unused'));

  @override
  Future<Result<bool, Exception>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => Result.error(Exception('unused'));
}

class const _TestMediaSource() extends MediaSource {
  @override
  String get id => 'test';

  @override
  String get name => 'Test';
}

class const _FailingVideoDetailRepository() implements VideoDetailRepository {
  @override
  Future<Result<VideoDetail, Exception>> getVideoDetail(String id) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool, Exception>> toggleLike(String id, bool isLiked) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool, Exception>> toggleFavorite(
    String id,
    bool isFavorited,
  ) async => Result.error(Exception('unused'));

  @override
  Future<Result<bool, Exception>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => Result.error(Exception('unused'));

  @override
  Future<Result<MediaStream, Exception>> getMediaStream(
    String id, {
    int? preferHeight,
    int? preferStreamId,
  }) async => Result.error(Exception('unused'));
}

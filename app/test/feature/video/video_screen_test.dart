import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/database/app_database.dart';
import 'package:app/database/dao/media_history_dao.dart';
import 'package:app/database/table/media.dart';
import 'package:app/datastore/media_history_settings.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:app/feature/video/video_screen.dart';
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

import 'fake_platform_player.dart';

void main() {
  testWidgets('video detail page exposes a page back button', (tester) async {
    var backPressed = false;

    // 设置测试视口大小，避免 PlaybackQueueSheet 在极小约束下溢出。
    // 必须在 pumpWidget 之前设置 tester.view.physicalSize，
    // 否则 MaterialApp 会捕获默认的 320x30 视口尺寸。
    // 使用更高的视口 (800x1200) 确保队列有足够空间滚动。
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      Provider<MediaSource>.value(
        value: const _TestMediaSource(),
        child: RepositoryProvider<VideoDetailRepository>.value(
          value: const _FailingVideoDetailRepository(),
          child: MaterialApp(
            home: VideoScreen(onBackClick: () => backPressed = true),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(backPressed, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
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
    }) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        Provider<MediaSource>.value(
          value: const _TestMediaSource(),
          child: RepositoryProvider<VideoDetailRepository>.value(
            value: const _ReadyStreamRepository(),
            child: RepositoryProvider<AppDatabase>.value(
              value: db,
              child: RepositoryProvider<MediaHistoryDao>.value(
                value: db.mediaHistoryDao,
                child: RepositoryProvider<PreferencesDataSource>.value(
                  value: preferences,
                  child: MaterialApp(
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

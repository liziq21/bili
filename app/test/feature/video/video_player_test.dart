import 'dart:async';

import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:app/feature/video/common_widgets/video_player.dart';
import 'package:app/feature/video/common_widgets/player_gesture_layer.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';

import 'fake_platform_player.dart';

import 'package:app/feature/video/video_queue_request.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:model/model.dart';
import 'package:app/design/design.dart';

void main() {
  Future<void> pumpPlayer(
    WidgetTester tester, {
    required VideoBloc bloc,
    MediaPlaybackController? controller,
    VideoQueueResult? queue,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: BlocProvider<VideoBloc>.value(
            value: bloc,
            child: VideoPlayer(
              controller: controller,
              queue: queue,
              // 真 Video 依赖原生 Texture，widget 测试里渲染会挂住 pump。
              surfaceBuilder: (_) => const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the loading view before the stream resolves', (
    WidgetTester tester,
  ) async {
    final bloc = VideoBloc(repository: _HangingStreamRepository());

    await pumpPlayer(tester, bloc: bloc);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(AppIcons.error), findsNothing);

    addTearDown(bloc.close);
  });

  testWidgets('renders the stream error inside the player area', (
    WidgetTester tester,
  ) async {
    final bloc = VideoBloc(repository: _FailingStreamRepository());

    await pumpPlayer(tester, bloc: bloc);
    bloc.add(const LoadMediaStream('BV123'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(
      find.textContaining('Failed to load video. Try again'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);

    addTearDown(bloc.close);
  });

  group('queue control bar', () {
    testWidgets(
      'next button drives controller.next and previous button drives controller.previous',
      (tester) async {
        final fake = FakePlatformPlayer();
        final controller = MediaPlaybackController(fake);

        final bloc = VideoBloc(repository: _NoStreamRepository());
        await pumpPlayer(tester, bloc: bloc, controller: controller);

        expect(find.byTooltip('Next'), findsOneWidget);
        expect(find.byTooltip('Previous'), findsOneWidget);

        await controller.openQueue([
          MediaStream(videoUrl: 'https://example.com/1.m4s'),
          MediaStream(videoUrl: 'https://example.com/2.m4s'),
        ]);
        await tester.pump();

        await tester.tap(find.byTooltip('Next'));
        await tester.pump();
        expect(fake.nextCalls, hasLength(1));
        expect(fake.previousCalls, isEmpty);

        await tester.tap(find.byTooltip('Previous'));
        await tester.pump();
        expect(fake.nextCalls, hasLength(1));
        expect(fake.previousCalls, hasLength(1));

        addTearDown(controller.dispose);
        addTearDown(bloc.close);
      },
    );

    testWidgets('cycling loop mode updates the loop mode tooltip dynamically', (
      tester,
    ) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);

      final bloc = VideoBloc(repository: _NoStreamRepository());
      await pumpPlayer(tester, bloc: bloc, controller: controller);

      await controller.openQueue([
        MediaStream(videoUrl: 'https://example.com/1.m4s'),
      ]);
      await tester.pump();

      expect(find.byTooltip('Loop: off'), findsOneWidget);

      await tester.tap(find.byTooltip('Loop: off'));
      await tester.pump();
      expect(find.byTooltip('Repeat one'), findsOneWidget);

      await tester.tap(find.byTooltip('Repeat one'));
      await tester.pump();
      expect(find.byTooltip('Repeat queue'), findsOneWidget);

      await tester.tap(find.byTooltip('Repeat queue'));
      await tester.pump();
      expect(find.byTooltip('Loop: off'), findsOneWidget);

      addTearDown(controller.dispose);
      addTearDown(bloc.close);
    });

    testWidgets('opens a sheet with queue metadata and edit controls', (
      tester,
    ) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _NoStreamRepository());
      await pumpPlayer(tester, bloc: bloc, controller: controller);

      await controller.openQueueItems([
        PlaybackQueueItem(
          stream: MediaStream(videoUrl: 'https://example.com/1.m4s'),
          videoId: 'one',
          title: 'First video',
          creatorName: 'First creator',
        ),
        PlaybackQueueItem(
          stream: MediaStream(videoUrl: 'https://example.com/2.m4s'),
          videoId: 'two',
          title: 'Second video',
        ),
      ]);
      await tester.pump();

      await tester.tap(find.byTooltip('Playback queue'));
      // The player below the sheet is still loading in this harness, so its
      // progress indicator keeps an animation scheduled indefinitely.
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('First video'), findsOneWidget);
      expect(find.text('First creator'), findsOneWidget);
      expect(find.text('Second video'), findsOneWidget);
      // The current item stays in the queue; only the following item has a
      // remove action.
      expect(find.byIcon(AppIcons.removeCircle), findsOneWidget);
      // Modal sheet keeps its dismiss control; the in-page pane hides it.
      expect(find.byIcon(AppIcons.close), findsOneWidget);

      addTearDown(controller.dispose);
      addTearDown(bloc.close);
    });

    testWidgets('opens the queue from a playlist request', (tester) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _StaticStreamRepository());
      final queue = VideoQueueResult(
        items: [
          VideoQueueItem(
            videoId: 'one',
            stream: MediaStream(videoUrl: 'https://example.com/1.m4s'),
          ),
          VideoQueueItem(
            videoId: 'two',
            stream: MediaStream(videoUrl: 'https://example.com/2.m4s'),
          ),
        ],
        requestedCount: 2,
      );

      bloc.add(const LoadMediaStream('one'));
      await tester.pump();
      await pumpPlayer(
        tester,
        bloc: bloc,
        controller: controller,
        queue: queue,
      );
      await tester.pump();

      // 队列以一次 openQueueItems 打开，而不是单条 open。
      expect(fake.openCalls, hasLength(1));
      expect(fake.openCalls.single, isA<Playlist>());
      expect(controller.queueItems, hasLength(2));
      expect(controller.queueItems.first.videoId, 'one');

      addTearDown(controller.dispose);
      addTearDown(bloc.close);
    });

    testWidgets('starts the queue at the requested index', (tester) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _StaticStreamRepository());
      final queue = VideoQueueResult(
        items: [
          VideoQueueItem(
            videoId: 'one',
            stream: MediaStream(videoUrl: 'https://example.com/1.m4s'),
          ),
          VideoQueueItem(
            videoId: 'two',
            stream: MediaStream(videoUrl: 'https://example.com/2.m4s'),
          ),
        ],
        startIndex: 1,
        requestedCount: 2,
      );

      bloc.add(const LoadMediaStream('two'));
      await tester.pump();
      await pumpPlayer(
        tester,
        bloc: bloc,
        controller: controller,
        queue: queue,
      );
      await tester.pump();

      final opened = fake.openCalls.single;
      expect(opened, isA<Playlist>());
      expect((opened as Playlist).index, 1);

      addTearDown(controller.dispose);
      addTearDown(bloc.close);
    });
  });

  group('retry and restore progress', () {
    test('retry reopens the stream', () async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final stream = MediaStream(videoUrl: 'https://example.com/v.m4s');

      await controller.open(stream);
      await controller.retry(stream);

      expect(fake.openCalls, hasLength(2));

      addTearDown(controller.dispose);
    });

    test('restorePositionSeconds triggers seek after open', () async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      controller.restorePositionSeconds = 30;

      await controller.open(MediaStream(videoUrl: 'https://example.com/1.m4s'));
      expect(fake.seekCalls, hasLength(1));
      expect(fake.seekCalls.first, const Duration(seconds: 30));
      expect(controller.restorePositionSeconds, 0);

      addTearDown(controller.dispose);
    });

    test('retry after restorePositionSeconds does not re-seek', () async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final stream = MediaStream(videoUrl: 'https://example.com/v.m4s');
      controller.restorePositionSeconds = 45;

      await controller.open(stream);
      expect(fake.seekCalls, hasLength(1));
      expect(fake.seekCalls.first, const Duration(seconds: 45));

      // retry 不应再次 seek（restorePositionSeconds 已清零）
      await controller.retry(stream);
      expect(fake.seekCalls, hasLength(1));
      expect(fake.openCalls, hasLength(2));

      addTearDown(controller.dispose);
    });
  });

  testWidgets(
    'opens a changed stream once and leaves reopening to the surface',
    (tester) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _NoStreamRepository());
      addTearDown(controller.dispose);
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: BlocProvider<VideoBloc>.value(
              value: bloc,
              child: VideoPlayer(
                controller: controller,
                surfaceBuilder: (_) => const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );

      final first = MediaStream(videoUrl: 'https://example.com/first.m4s');
      final second = MediaStream(videoUrl: 'https://example.com/second.m4s');
      bloc.add(MediaStreamChanged(first));
      await tester.pump();
      await tester.pump();
      expect(fake.openCalls, hasLength(1));

      bloc.add(MediaStreamChanged(second));
      await tester.pump();
      await tester.pump();
      expect(fake.openCalls, hasLength(2));
    },
  );

  testWidgets(
    'embedded control bar shows current/total time and seeks on drag',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _ReadyStreamRepository());
      addTearDown(controller.dispose);
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: BlocProvider<VideoBloc>.value(
              value: bloc,
              child: VideoPlayer(
                controller: controller,
                surfaceBuilder: (_) => const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      bloc.add(const LoadMediaStream('BV123'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();

      fake.emitDuration(const Duration(minutes: 3, seconds: 20));
      fake.emitPosition(const Duration(minutes: 1, seconds: 5));
      await tester.pump();

      // #665：竖屏内嵌播放器此前只有清晰度 / 倍速 / 全屏按钮，看不到播放
      // 进度，也看不到当前时间和总时长。
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('1:05'), findsOneWidget);
      expect(find.text('3:20'), findsOneWidget);

      await tester.drag(find.byType(Slider), const Offset(60, 0));
      await tester.pump();

      // 断言 seek 到的是拖到的位置，而不是随便一个位置（比如 0）。
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(
        slider.value,
        greaterThan(const Duration(minutes: 1, seconds: 5).inMilliseconds),
      );
      expect(fake.seekCalls, hasLength(1));
      expect(
        fake.seekCalls.single,
        Duration(milliseconds: slider.value.round()),
      );
    },
  );

  testWidgets('the thumb holds the seek target until the player reports it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final fake = FakePlatformPlayer();
    final controller = MediaPlaybackController(fake);
    final bloc = VideoBloc(repository: _ReadyStreamRepository());
    addTearDown(controller.dispose);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: BlocProvider<VideoBloc>.value(
            value: bloc,
            child: VideoPlayer(
              controller: controller,
              surfaceBuilder: (_) => const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    bloc.add(const LoadMediaStream('BV123'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump();

    fake.emitDuration(const Duration(minutes: 3, seconds: 20));
    fake.emitPosition(const Duration(minutes: 1, seconds: 5));
    await tester.pump();

    await tester.drag(find.byType(Slider), const Offset(60, 0));
    await tester.pump();
    final target = tester.widget<Slider>(find.byType(Slider)).value;

    // seek 是异步的：播放器还没回报新位置时，滑块必须停在拖到的位置，
    // 否则松手瞬间会跳回旧位置再跳回来。
    fake.emitPosition(const Duration(minutes: 1, seconds: 5));
    await tester.pump();
    expect(tester.widget<Slider>(find.byType(Slider)).value, target);

    // 位置追上目标后交还给播放器状态。
    fake.emitPosition(Duration(milliseconds: target.round()));
    await tester.pump();
    expect(
      tester.widget<Slider>(find.byType(Slider)).value,
      closeTo(target, 1),
    );
  });

  testWidgets('a drag that started before the media changed is not seeked', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final fake = FakePlatformPlayer();
    final controller = MediaPlaybackController(fake);
    final bloc = VideoBloc(repository: _ReadyStreamRepository());
    addTearDown(controller.dispose);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: BlocProvider<VideoBloc>.value(
            value: bloc,
            child: VideoPlayer(
              controller: controller,
              surfaceBuilder: (_) => const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    bloc.add(const LoadMediaStream('BV123'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump();

    fake.emitDuration(const Duration(minutes: 3, seconds: 20));
    fake.emitPosition(const Duration(minutes: 1, seconds: 5));
    await tester.pump();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Slider)),
    );
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();

    // 拖动途中换了媒体：旧目标对新媒体没有意义，松手不能 seek。
    fake.emitDuration(const Duration(minutes: 5));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(fake.seekCalls, isEmpty);
  });

  testWidgets(
    'short embedded player keeps the picture and drops the progress row',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      Future<void> pumpInHeight(double height) async {
        final fake = FakePlatformPlayer();
        final controller = MediaPlaybackController(fake);
        final bloc = VideoBloc(repository: _ReadyStreamRepository());
        addTearDown(controller.dispose);
        addTearDown(bloc.close);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: SizedBox(
                height: height,
                child: BlocProvider<VideoBloc>.value(
                  value: bloc,
                  child: VideoPlayer(
                    controller: controller,
                    surfaceBuilder: (_) =>
                        const SizedBox.expand(key: ValueKey('surface')),
                  ),
                ),
              ),
            ),
          ),
        );
        bloc.add(const LoadMediaStream('BV123'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));
        await tester.pump();
        fake.emitDuration(const Duration(minutes: 3, seconds: 20));
        fake.emitPosition(const Duration(minutes: 1, seconds: 5));
        await tester.pump();
      }

      // 矮窗口：控制栏放不下两行，进度行让位给画面，画面不能被压成 0 高。
      await pumpInHeight(180);
      expect(find.byType(Slider), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey('surface'))).height,
        greaterThan(0),
      );

      // 高度够时进度条回来。
      await pumpInHeight(600);
      expect(find.byType(Slider), findsOneWidget);
    },
  );

  group('video aspect ratio', () {
    /// 把播放器放进固定尺寸的盒子并让流就绪，用于断言画面比例。
    Future<void> pumpSized(
      WidgetTester tester, {
      required VideoBloc bloc,
      required MediaPlaybackController controller,
      required Size size,
      bool boundedHeight = true,
    }) async {
      if (!boundedHeight) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
      }
      final player = VideoPlayer(
        controller: controller,
        surfaceBuilder: (_) => const ColoredBox(color: Color(0xFF000000)),
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: BlocProvider<VideoBloc>.value(
              value: bloc,
              // 无高度上限时放进滚动容器：页面就是这种「高度不设限」的上下文。
              child: boundedHeight
                  ? SizedBox(
                      width: size.width,
                      height: size.height,
                      child: player,
                    )
                  : SingleChildScrollView(
                      child: SizedBox(width: size.width, child: player),
                    ),
            ),
          ),
        ),
      );
      bloc.add(const LoadMediaStream('BV123'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();
    }

    /// 画面本体（AspectRatio 包裹的那块）的宽高比。
    double surfaceAspectRatio(WidgetTester tester) {
      final rect = tester.getRect(find.byType(AspectRatio));
      return rect.width / rect.height;
    }

    testWidgets('falls back to 16:9 until the video size is known', (
      tester,
    ) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _ReadyStreamRepository());
      addTearDown(controller.dispose);
      addTearDown(bloc.close);

      await pumpSized(
        tester,
        bloc: bloc,
        controller: controller,
        size: const Size(980, 390),
      );

      expect(surfaceAspectRatio(tester), closeTo(16 / 9, 0.01));
    });

    testWidgets('portrait video becomes a full-height narrow column', (
      tester,
    ) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _ReadyStreamRepository());
      addTearDown(controller.dispose);
      addTearDown(bloc.close);

      await pumpSized(
        tester,
        bloc: bloc,
        controller: controller,
        size: const Size(980, 390),
      );

      fake.emitVideoParams(const VideoParams(dw: 1080, dh: 1920));
      await tester.pump();

      expect(surfaceAspectRatio(tester), closeTo(1080 / 1920, 0.01));
      final rect = tester.getRect(find.byType(AspectRatio));
      expect(rect.height, greaterThan(rect.width));
      // 竖条撑满播放器给画面留的高度，而不是缩成容器中央的一小块。
      expect(rect.width, lessThan(300));
      expect(rect.height, greaterThan(250));
    });

    testWidgets('rotation metadata turns a landscape-encoded portrait clip', (
      tester,
    ) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _ReadyStreamRepository());
      addTearDown(controller.dispose);
      addTearDown(bloc.close);

      await pumpSized(
        tester,
        bloc: bloc,
        controller: controller,
        size: const Size(980, 390),
      );

      // 竖拍视频常以横向尺寸编码 + rotate 元数据到达。
      fake.emitVideoParams(const VideoParams(dw: 1920, dh: 1080, rotate: 90));
      await tester.pump();

      expect(surfaceAspectRatio(tester), closeTo(1080 / 1920, 0.01));
    });

    testWidgets('landscape video keeps the wide shape', (tester) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _ReadyStreamRepository());
      addTearDown(controller.dispose);
      addTearDown(bloc.close);

      await pumpSized(
        tester,
        bloc: bloc,
        controller: controller,
        size: const Size(980, 390),
      );

      fake.emitVideoParams(const VideoParams(dw: 1920, dh: 1080));
      await tester.pump();

      expect(surfaceAspectRatio(tester), closeTo(1920 / 1080, 0.01));
      final rect = tester.getRect(find.byType(AspectRatio));
      expect(rect.width, greaterThan(rect.height));
    });

    testWidgets('a square video is capped by the viewport height too', (
      tester,
    ) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _ReadyStreamRepository());
      addTearDown(controller.dispose);
      addTearDown(bloc.close);

      // 高度无界的页面里，正方形视频按宽度撑出的高度同样会顶掉下方内容。
      await pumpSized(
        tester,
        bloc: bloc,
        controller: controller,
        size: const Size(980, 720),
        boundedHeight: false,
      );

      fake.emitVideoParams(const VideoParams(dw: 1080, dh: 1080));
      await tester.pump();

      final rect = tester.getRect(find.byType(AspectRatio));
      expect(rect.width / rect.height, closeTo(1, 0.01));
      expect(rect.height, lessThanOrEqualTo(720 * 0.6 + 0.5));
    });

    testWidgets('the surface is not rebuilt when the shape arrives', (
      tester,
    ) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _ReadyStreamRepository());
      addTearDown(controller.dispose);
      addTearDown(bloc.close);

      await pumpSized(
        tester,
        bloc: bloc,
        controller: controller,
        size: const Size(980, 720),
        boundedHeight: false,
      );
      final before = tester.element(find.byType(AspectRatio));

      fake.emitVideoParams(const VideoParams(dw: 1080, dh: 1920));
      await tester.pump();

      // 尺寸到达时只改尺寸，不换布局结构：换结构会重建画面并重新打开媒体。
      expect(tester.element(find.byType(AspectRatio)), same(before));
    });

    testWidgets('explicit aspectRatio wins over the video size', (
      tester,
    ) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _ReadyStreamRepository());
      addTearDown(controller.dispose);
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: BlocProvider<VideoBloc>.value(
              value: bloc,
              child: SizedBox(
                width: 400,
                height: 400,
                child: VideoPlayer(
                  controller: controller,
                  aspectRatio: 1,
                  surfaceBuilder: (_) =>
                      const ColoredBox(color: Color(0xFF000000)),
                ),
              ),
            ),
          ),
        ),
      );
      bloc.add(const LoadMediaStream('BV123'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();

      fake.emitVideoParams(const VideoParams(dw: 1080, dh: 1920));
      await tester.pump();

      expect(surfaceAspectRatio(tester), closeTo(1, 0.01));
    });
  });

  group('fullscreen layout', () {
    /// 把播放器放进固定尺寸的盒子，便于断言铺满与 16:9 内嵌的差别。
    Future<void> pumpSurface(
      WidgetTester tester, {
      required VideoBloc bloc,
      required MediaPlaybackController controller,
      required bool fullscreen,
      Size size = const Size(400, 400),
      VoidCallback? onToggleFullscreen,
      VoidCallback? onMinimize,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: BlocProvider<VideoBloc>.value(
              value: bloc,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: VideoPlayer(
                  controller: controller,
                  fullscreen: fullscreen,
                  onToggleFullscreen: onToggleFullscreen,
                  onMinimize: onMinimize,
                  // 原生 Video 会让 widget 测试挂住，换成纯 Flutter 画面。
                  surfaceBuilder: (_) =>
                      const ColoredBox(color: Color(0xFF000000)),
                ),
              ),
            ),
          ),
        ),
      );
      // bloc 构造不自动加载，与既有用例一致地显式派发解析事件。
      bloc.add(const LoadMediaStream('BV123'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();
    }

    testWidgets('fills the whole box instead of a 16:9 area', (tester) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _ReadyStreamRepository());
      addTearDown(controller.dispose);
      addTearDown(bloc.close);

      await pumpSurface(
        tester,
        bloc: bloc,
        controller: controller,
        fullscreen: true,
      );

      // 全屏铺满：400x400 全给画面，不再是 400x225 的 16:9 内嵌。
      expect(tester.getSize(find.byType(VideoPlayer)), const Size(400, 400));
      expect(find.byType(AspectRatio), findsNothing);
    });

    testWidgets('embedded mode keeps the 16:9 area', (tester) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _ReadyStreamRepository());
      addTearDown(controller.dispose);
      addTearDown(bloc.close);

      await pumpSurface(
        tester,
        bloc: bloc,
        controller: controller,
        fullscreen: false,
      );

      // 画面本体受 AspectRatio 约束：宽 400 -> 16:9 高 225，盒内上下留白。
      expect(tester.getSize(find.byType(AspectRatio)), const Size(400, 225));
    });

    testWidgets('embedded controls stay below the video area', (tester) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _ReadyStreamRepository());
      addTearDown(controller.dispose);
      addTearDown(bloc.close);

      await pumpSurface(
        tester,
        bloc: bloc,
        controller: controller,
        fullscreen: false,
      );

      final videoRect = tester.getRect(find.byType(AspectRatio));
      final controlsRect = tester.getRect(find.byTooltip('Fullscreen'));
      expect(controlsRect.top, greaterThanOrEqualTo(videoRect.bottom));
    });

    testWidgets('shows the categorized error with retry action', (
      tester,
    ) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _ReadyStreamRepository());
      addTearDown(controller.dispose);
      addTearDown(bloc.close);

      await pumpSurface(
        tester,
        bloc: bloc,
        controller: controller,
        fullscreen: false,
      );

      fake.injectPlaybackError('decoder rejected codec');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.textContaining('Decoder error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Decoder error'), findsNothing);
    });

    testWidgets('offers skip when a later queue item is available', (
      tester,
    ) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _ReadyStreamRepository());
      addTearDown(controller.dispose);
      addTearDown(bloc.close);

      await pumpSurface(
        tester,
        bloc: bloc,
        controller: controller,
        fullscreen: false,
      );
      await controller.openQueue([
        MediaStream(videoUrl: 'https://example.com/1.m4s'),
        MediaStream(videoUrl: 'https://example.com/2.m4s'),
      ]);
      await tester.pump();

      fake.injectPlaybackError('decoder rejected codec');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.text('Skip'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pump();
      expect(fake.nextCalls, hasLength(1));
    });

    testWidgets('hides the overlay controls until the surface is tapped', (
      tester,
    ) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _ReadyStreamRepository());
      addTearDown(controller.dispose);
      addTearDown(bloc.close);

      await pumpSurface(
        tester,
        bloc: bloc,
        controller: controller,
        fullscreen: true,
      );

      expect(find.byTooltip('Fullscreen'), findsNothing);

      // 单击画面唤出控制层（含退出全屏按钮）。
      await tester.tap(find.byType(PlayerGestureLayer));
      // onTap 与 onDoubleTap 共存时，首次单击要等双击判定窗结束才回调。
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byTooltip('Back'), findsOneWidget);
    });

    testWidgets('restores the controls when leaving fullscreen', (
      tester,
    ) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _ReadyStreamRepository());
      addTearDown(controller.dispose);
      addTearDown(bloc.close);

      await pumpSurface(
        tester,
        bloc: bloc,
        controller: controller,
        fullscreen: false,
      );
      expect(find.byTooltip('Fullscreen'), findsOneWidget);

      // 同一位置重建为全屏：控制层收起；再重建回内嵌：控制层常显。
      await pumpSurface(
        tester,
        bloc: bloc,
        controller: controller,
        fullscreen: true,
      );
      expect(find.byTooltip('Back'), findsNothing);

      await pumpSurface(
        tester,
        bloc: bloc,
        controller: controller,
        fullscreen: false,
      );
      expect(find.byTooltip('Fullscreen'), findsOneWidget);
    });

    testWidgets('the minimize button only exists in fullscreen', (
      tester,
    ) async {
      final fake = FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final bloc = VideoBloc(repository: _ReadyStreamRepository());
      addTearDown(controller.dispose);
      addTearDown(bloc.close);
      var minimized = false;

      await pumpSurface(
        tester,
        bloc: bloc,
        controller: controller,
        fullscreen: false,
        onMinimize: () => minimized = true,
      );
      expect(find.byIcon(AppIcons.pictureInPicture), findsNothing);

      await pumpSurface(
        tester,
        bloc: bloc,
        controller: controller,
        fullscreen: true,
        onMinimize: () => minimized = true,
      );
      await tester.tap(find.byType(PlayerGestureLayer));
      // onTap 与 onDoubleTap 共存时，首次单击要等双击判定窗结束才回调。
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byIcon(AppIcons.pictureInPicture));
      await tester.pump(const Duration(milliseconds: 50));

      expect(minimized, isTrue);
    });
  });
}

/// 返回固定可播地址的仓库：让 bloc 在首次 pump 后就有 stream，便于断言
/// 播放器按队列还是按单条打开。
class _StaticStreamRepository() extends _NoStreamRepository {
  @override
  Future<Result<MediaStream, Exception>> getMediaStream(
    String id, {
    int? preferHeight,
    int? preferStreamId,
  }) async =>
      Result.success(MediaStream(videoUrl: 'https://example.com/$id.m4s'));
}

class _NoStreamRepository() implements VideoDetailRepository {
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
  }) async {
    return Completer<Result<MediaStream, Exception>>().future;
  }
}

class _HangingStreamRepository() implements VideoDetailRepository {
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
  }) async {
    return Completer<Result<MediaStream, Exception>>().future;
  }
}

class _FailingStreamRepository() implements VideoDetailRepository {
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
  }) async => Result.error(Exception('签名过期'));
}

/// 立即返回可播流：让画面本体（含浮层控制）渲染出来。
class _ReadyStreamRepository() implements VideoDetailRepository {
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
    MediaStream(
      videoUrl: 'https://example.com/v.m4s',
      height: 1080,
      bitrate: 3000000,
    ),
  );
}

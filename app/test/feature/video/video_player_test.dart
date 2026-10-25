import 'dart:async';

import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:app/feature/video/common_widgets/video_player.dart';
import 'package:app/feature/video/common_widgets/player_gesture_layer.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:model/model.dart';

void main() {
  Future<void> pumpPlayer(
    WidgetTester tester, {
    required VideoBloc bloc,
    MediaPlaybackController? controller,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<VideoBloc>.value(
            value: bloc,
            child: VideoPlayer(controller: controller),
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
    expect(find.byIcon(Icons.error_outline), findsNothing);

    addTearDown(bloc.close);
  });

  testWidgets('renders generic error message', (
    WidgetTester tester,
  ) async {
    final bloc = VideoBloc(repository: _FailingStreamRepository());

    await pumpPlayer(tester, bloc: bloc);
    bloc.add(const LoadMediaStream('BV123'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // Verifies generic error text is rendered and raw exception string '签名过期' is masked from UI.
    expect(find.textContaining('签名过期'), findsNothing);

    addTearDown(bloc.close);
  });

  group('queue control bar', () {
    testWidgets(
      'next button drives controller.next and previous button drives controller.previous',
      (tester) async {
        final fake = _FakePlatformPlayer();
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
      final fake = _FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);

      final bloc = VideoBloc(repository: _NoStreamRepository());
      await pumpPlayer(tester, bloc: bloc, controller: controller);

      await controller.openQueue([
        MediaStream(videoUrl: 'https://example.com/1.m4s'),
      ]);
      await tester.pump();

      expect(find.byTooltip('Loop off'), findsOneWidget);

      await tester.tap(find.byTooltip('Loop off'));
      await tester.pump();
      expect(find.byTooltip('Loop one'), findsOneWidget);

      await tester.tap(find.byTooltip('Loop one'));
      await tester.pump();
      expect(find.byTooltip('Loop queue'), findsOneWidget);

      await tester.tap(find.byTooltip('Loop queue'));
      await tester.pump();
      expect(find.byTooltip('Loop off'), findsOneWidget);

      addTearDown(controller.dispose);
      addTearDown(bloc.close);
    });
  });

  group('retry and restore progress', () {
    test('retry reopens the stream', () async {
      final fake = _FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      final stream = MediaStream(videoUrl: 'https://example.com/v.m4s');

      await controller.open(stream);
      await controller.retry(stream);

      expect(fake.openCalls, hasLength(2));

      addTearDown(controller.dispose);
    });

    test('restorePositionSeconds triggers seek after open', () async {
      final fake = _FakePlatformPlayer();
      final controller = MediaPlaybackController(fake);
      controller.restorePositionSeconds = 30;

      await controller.open(MediaStream(videoUrl: 'https://example.com/1.m4s'));
      expect(fake.seekCalls, hasLength(1));
      expect(fake.seekCalls.first, const Duration(seconds: 30));
      expect(controller.restorePositionSeconds, 0);

      addTearDown(controller.dispose);
    });

    test('retry after restorePositionSeconds does not re-seek', () async {
      final fake = _FakePlatformPlayer();
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
      final fake = _FakePlatformPlayer();
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
      final fake = _FakePlatformPlayer();
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
      final fake = _FakePlatformPlayer();
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

    testWidgets('hides the overlay controls until the surface is tapped', (
      tester,
    ) async {
      final fake = _FakePlatformPlayer();
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
      final fake = _FakePlatformPlayer();
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
      final fake = _FakePlatformPlayer();
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
      expect(find.byIcon(Icons.picture_in_picture_alt), findsNothing);

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

      await tester.tap(find.byIcon(Icons.picture_in_picture_alt));
      await tester.pump(const Duration(milliseconds: 50));

      expect(minimized, isTrue);
    });
  });
}

class _NoStreamRepository implements VideoDetailRepository {
  @override
  Future<Result<VideoDetail>> getVideoDetail(String id) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool>> toggleLike(String id, bool isLiked) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => Result.error(Exception('unused'));

  @override
  Future<Result<MediaStream>> getMediaStream(
    String id, {
    int? preferHeight,
    int? preferStreamId,
  }) async {
    return Completer<Result<MediaStream>>().future;
  }
}

// ignore_for_file: close_sinks
class _FakePlatformPlayer extends Fake implements PlatformPlayer {
  _FakePlatformPlayer() {
    stream = PlayerStream(
      _playlist.stream,
      _playing.stream,
      _completed.stream,
      _position.stream,
      _duration.stream,
      _volume.stream,
      _rate.stream,
      _pitch.stream,
      _buffering.stream,
      _bufferingPercentage.stream,
      _buffer.stream,
      _playlistMode.stream,
      _shuffle.stream,
      _audioParams.stream,
      _videoParams.stream,
      _audioBitrate.stream,
      _audioDevice.stream,
      _audioDevices.stream,
      _track.stream,
      _tracks.stream,
      _width.stream,
      _height.stream,
      _subtitle.stream,
      _log.stream,
      _error.stream,
    );
  }

  final _playlist = StreamController<Playlist>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _completed = StreamController<bool>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration>.broadcast();
  final _volume = StreamController<double>.broadcast();
  final _rate = StreamController<double>.broadcast();
  final _pitch = StreamController<double>.broadcast();
  final _buffering = StreamController<bool>.broadcast();
  final _buffer = StreamController<Duration>.broadcast();
  final _bufferingPercentage = StreamController<double>.broadcast();
  final _playlistMode = StreamController<PlaylistMode>.broadcast();
  final _shuffle = StreamController<bool>.broadcast();
  final _audioParams = StreamController<AudioParams>.broadcast();
  final _videoParams = StreamController<VideoParams>.broadcast();
  final _audioBitrate = StreamController<double?>.broadcast();
  final _audioDevice = StreamController<AudioDevice>.broadcast();
  final _audioDevices = StreamController<List<AudioDevice>>.broadcast();
  final _track = StreamController<Track>.broadcast();
  final _tracks = StreamController<Tracks>.broadcast();
  final _width = StreamController<int?>.broadcast();
  final _height = StreamController<int?>.broadcast();
  final _subtitle = StreamController<List<String>>.broadcast();
  final _log = StreamController<PlayerLog>.broadcast();
  final _error = StreamController<String>.broadcast();

  @override
  late PlayerState state;

  @override
  late PlayerStream stream;

  /// [PlatformPlayer.isVideoControllerAttached] — `VideoController`
  /// constructor writes this; [dispose] reads it.
  @override
  bool isVideoControllerAttached = false;

  /// 固定的原生句柄：[NativeVideoController.create] 用它做缓存键与纹理注册。
  @override
  final Future<int> handle = Future.value(42);

  /// [NativeVideoController.create] 注册 [Player.dispose] 回调到这里。
  @override
  final List<Future<void> Function()> release = [];

  final List<int> nextCalls = [];
  final List<int> previousCalls = [];
  final List<Playable> openCalls = [];
  final List<Duration> seekCalls = [];
  final List<double> rateCalls = [];

  @override
  Future<void> next() async => nextCalls.add(0);

  @override
  Future<void> previous() async => previousCalls.add(0);

  @override
  Future<void> jump(int index) async {}

  @override
  Future<void> add(Media media) async {}

  @override
  Future<void> remove(int index) async {}

  @override
  Future<void> move(int from, int to) async {}

  @override
  Future<void> setPlaylistMode(PlaylistMode mode) async {
    _playlistMode.add(mode);
  }

  @override
  Future<void> open(
    Playable playable, {
    bool play = true,
    bool synchronized = true,
  }) async {
    openCalls.add(playable);
    if (playable is Playlist) {
      _playlist.add(playable);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    seekCalls.add(position);
  }

  @override
  Future<void> setRate(double rate) async {
    rateCalls.add(rate);
    _rate.add(rate);
  }

  /// 投喂一次速率事件，驱动 [MediaPlaybackController.states] 的 rate 字段。
  void emitRate(double rate) => _rate.add(rate);

  @override
  Future<void> dispose() async {}

  void injectPlaybackError(String message) => _error.add(message);
}

class _HangingStreamRepository implements VideoDetailRepository {
  @override
  Future<Result<VideoDetail>> getVideoDetail(String id) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool>> toggleLike(String id, bool isLiked) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => Result.error(Exception('unused'));

  @override
  Future<Result<MediaStream>> getMediaStream(
    String id, {
    int? preferHeight,
    int? preferStreamId,
  }) async {
    return Completer<Result<MediaStream>>().future;
  }
}

class _FailingStreamRepository implements VideoDetailRepository {
  @override
  Future<Result<VideoDetail>> getVideoDetail(String id) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool>> toggleLike(String id, bool isLiked) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => Result.error(Exception('unused'));

  @override
  Future<Result<MediaStream>> getMediaStream(
    String id, {
    int? preferHeight,
    int? preferStreamId,
  }) async => Result.error(Exception('签名过期'));
}

/// 立即返回可播流：让画面本体（含浮层控制）渲染出来。
class _ReadyStreamRepository implements VideoDetailRepository {
  @override
  Future<Result<VideoDetail>> getVideoDetail(String id) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool>> toggleLike(String id, bool isLiked) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool>> toggleFavorite(String id, bool isFavorited) async =>
      Result.error(Exception('unused'));

  @override
  Future<Result<bool>> toggleSubscribe(
    String creatorId,
    bool isSubscribed,
  ) async => Result.error(Exception('unused'));

  @override
  Future<Result<MediaStream>> getMediaStream(
    String id, {
    int? preferHeight,
    int? preferStreamId,
  }) async => Result.ok(
    MediaStream(
      videoUrl: 'https://example.com/v.m4s',
      height: 1080,
      bitrate: 3000000,
    ),
  );
}

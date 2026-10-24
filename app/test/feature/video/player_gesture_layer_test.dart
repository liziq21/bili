import 'dart:async';

import 'package:app/feature/video/common_widgets/playback_speed_chip.dart';
import 'package:app/feature/video/common_widgets/player_gesture_layer.dart';
import 'package:app/feature/video/player/brightness_service.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:data/data.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';

/// 假播放器：只实现手势层路径需要的方法。
class _FakePlatformPlayer() extends Fake implements PlatformPlayer {
  final _playlist = StreamController<Playlist>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration>.broadcast();
  final _volume = StreamController<double>.broadcast();
  final List<double> volumeCalls = [];
  final List<Duration> seekCalls = [];

  @override
  bool isVideoControllerAttached = false;

  @override
  PlayerStream get stream => PlayerStream(
    _playlist.stream, // playlist
    const Stream<bool>.empty(), // playing
    const Stream<bool>.empty(), // completed
    _position.stream, // position
    _duration.stream, // duration
    _volume.stream, // volume
    const Stream<double>.empty(), // rate
    const Stream<double>.empty(), // pitch
    const Stream<bool>.empty(), // buffering
    const Stream<double>.empty(), // bufferingPercentage
    const Stream<Duration>.empty(), // buffer
    const Stream<PlaylistMode>.empty(), // playlistMode
    const Stream<bool>.empty(), // shuffle
    const Stream<AudioParams>.empty(), // audioParams
    const Stream<VideoParams>.empty(), // videoParams
    const Stream<double?>.empty(), // audioBitrate
    const Stream<AudioDevice>.empty(), // audioDevice
    const Stream<List<AudioDevice>>.empty(), // audioDevices
    const Stream<Track>.empty(), // track
    const Stream<Tracks>.empty(), // tracks
    const Stream<int?>.empty(), // width
    const Stream<int?>.empty(), // height
    const Stream<List<String>>.empty(), // subtitle
    const Stream<PlayerLog>.empty(), // log
    const Stream<String>.empty(), // error
  );

  @override
  Future<void> open(
    Playable playable, {
    bool play = true,
    bool synchronized = true,
  }) async {
    if (playable is Playlist) _playlist.add(playable);
  }

  @override
  Future<void> seek(Duration position) async {
    seekCalls.add(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    volumeCalls.add(volume);
    // 回发让 PlaybackState.volume 更新，下一次拖动的起点随之刷新。
    _volume.add(volume * 100);
  }

  @override
  Future<void> setRate(double rate) async {}

  @override
  Future<void> dispose() async {}

  /// 测试发射位置/时长事件（私有流不跨库可见）。
  void emitPosition(Duration position) => _position.add(position);
  void emitDuration(Duration duration) => _duration.add(duration);

  void disposeStreams() {
    _playlist.close();
    _position.close();
    _duration.close();
    _volume.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('PiliPlus');
  late _FakePlatformPlayer fake;
  late MediaPlaybackController controller;
  late BoostRateController boost;
  final brightnessCalls = <MethodCall>[];

  setUp(() {
    fake = _FakePlatformPlayer();
    controller = MediaPlaybackController(fake);
    boost = BoostRateController(controller);
    brightnessCalls.clear();
  });

  tearDown(() {
    controller.dispose();
    fake.disposeStreams();
    boost.dispose();
  });

  test('vertical gesture zones map to brightness and volume', () {
    expect(
      playerVerticalControlFor(localX: 49, width: 100),
      PlayerVerticalControl.brightness,
    );
    expect(
      playerVerticalControlFor(localX: 50, width: 100),
      PlayerVerticalControl.volume,
    );
  });

  test('seek preview clamps and formats its target timestamp', () {
    final target = calculatePlayerSeekTarget(
      base: const Duration(seconds: 30),
      deltaX: 50,
      durationPerPixel: 1.2,
      duration: const Duration(minutes: 2),
    );

    expect(target, const Duration(seconds: 90));
    expect(formatPlayerTimestamp(target), '01:30');
    expect(
      formatPlayerTimestamp(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
    expect(
      calculatePlayerSeekTarget(
        base: const Duration(seconds: 115),
        deltaX: 50,
        durationPerPixel: 1.2,
        duration: const Duration(minutes: 2),
      ),
      const Duration(minutes: 2),
    );
  });

  /// 直接 pump 手势层，不经过原生 `Video`：真 `VideoController` 在有
  /// libmpv 的环境会走原生 ffi，widget 测试里渲染它会段错误。
  Future<void> pumpLayer(
    WidgetTester tester, {
    VoidCallback? onDoubleTapScreen,
  }) async {
    // [_subscribe] 由 openQueue 触发：不打开队列，位置/时长流无人监听。
    await controller.openQueue([MediaStream(videoUrl: 'https://e.com/v.m4s')]);
    fake.emitPosition(const Duration(seconds: 30));
    fake.emitDuration(const Duration(minutes: 2));
    await tester.pump();

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'setBrightness' || call.method == 'getBrightness') {
        brightnessCalls.add(call);
      }
      // 起点亮度 0.8，给左半侧亮度拖动一个已知的初值。
      if (call.method == 'getBrightness') return 0.8;
      return true;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 100,
            child: PlayerGestureLayer(
              controller: controller,
              brightnessService: BrightnessService(),
              boost: boost,
              onDoubleTapScreen: onDoubleTapScreen,
              child: const ColoredBox(
                color: Color(0xFF000000),
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
    // 等 getBrightness 的异步回填落地。
    await tester.pump();
  }

  group('PlayerGestureLayer', () {
    testWidgets('horizontal drag seeks to the target on release', (
      tester,
    ) async {
      await pumpLayer(tester);

      // 拖动手势要先越过触控阈值才被识别，识别点之后的位移才计入快进，
      // 故先小幅移动触发识别，再拖要计入的距离。
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PlayerGestureLayer)),
      );
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      // 整屏 200px 扫过两倍时长（120s），即 1.2s/px；拖 50px = +60s。
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      expect(find.text('01:30 / 02:00'), findsOneWidget);
      await gesture.up();
      await tester.pump();

      // 起点位置 30s，落点 = 30s + 60s。
      expect(fake.seekCalls, contains(const Duration(seconds: 90)));
      // 双击识别器留有 countdown timer，收尾前推进过去
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('horizontal drag is clamped to the duration', (tester) async {
      await pumpLayer(tester);

      // 150px = +180s，超出 120s 时长，应落在末尾。
      await tester.drag(find.byType(PlayerGestureLayer), const Offset(150, 0));
      await tester.pump();

      expect(fake.seekCalls, contains(const Duration(minutes: 2)));
      // 双击识别器留有 countdown timer，收尾前推进过去
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('vertical drag on the right half lowers the volume', (
      tester,
    ) async {
      await pumpLayer(tester);

      // 起点 (100, 50) 恰在中线，判为右半侧（音量）。
      final gesture = await tester.startGesture(const Offset(100, 50));
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 50));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // 初值 1.0，下拉 50px（半屏高）= -0.5；平台层量程 0..100，
      // 控制器把 0..1 换算后下发。
      expect(fake.volumeCalls, contains(50.0));
      // 双击识别器留有 countdown timer，收尾前推进过去
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('vertical drag on the left half lowers the brightness', (
      tester,
    ) async {
      await pumpLayer(tester);

      final gesture = await tester.startGesture(const Offset(50, 50));
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 50));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final setBrightness = brightnessCalls
          .where((call) => call.method == 'setBrightness')
          .toList();
      expect(setBrightness, isNotEmpty);
      // 初值 0.8，下拉半屏 = -0.5；浮点留容差。
      expect(
        setBrightness.last.arguments['brightness'] as double,
        closeTo(0.3, 1e-9),
      );
      // 双击识别器留有 countdown timer，收尾前推进过去
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('dragging the left side to the bottom restores system', (
      tester,
    ) async {
      await pumpLayer(tester);

      final gesture = await tester.startGesture(const Offset(50, 50));
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      // 80px 把 0.8 拉到 0.0，松手应恢复跟随系统而非锁死最暗。
      await gesture.moveBy(const Offset(0, 80));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      final setBrightness = brightnessCalls
          .where((call) => call.method == 'setBrightness')
          .toList();
      expect(setBrightness, isNotEmpty);
      expect(setBrightness.last.arguments['brightness'], isNull);
      // 双击识别器留有 countdown timer，收尾前推进过去
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('touch double tap toggles fullscreen', (tester) async {
      var fullscreenToggles = 0;
      await pumpLayer(tester, onDoubleTapScreen: () => fullscreenToggles++);

      await tester.tapAt(const Offset(150, 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(const Offset(150, 50));
      await tester.pump(const Duration(milliseconds: 100));

      expect(fullscreenToggles, 1);
      expect(fake.seekCalls, isEmpty);
    });
    testWidgets('two-finger tap toggles fullscreen', (tester) async {
      var fullscreenToggles = 0;
      await pumpLayer(tester, onDoubleTapScreen: () => fullscreenToggles++);

      final first = TestPointer(1, PointerDeviceKind.touch);
      final second = TestPointer(2, PointerDeviceKind.touch);
      tester.binding.handlePointerEvent(first.down(const Offset(60, 50)));
      tester.binding.handlePointerEvent(second.down(const Offset(140, 50)));
      tester.binding.handlePointerEvent(first.up());
      tester.binding.handlePointerEvent(second.up());
      await tester.pump();

      expect(fullscreenToggles, 1);
      expect(fake.seekCalls, isEmpty);
    });
    testWidgets(
      'mouse double tap goes to the screen callback instead of seeking',
      (tester) async {
        var screenTaps = 0;
        await pumpLayer(tester, onDoubleTapScreen: () => screenTaps++);

        final pointer = TestPointer(7, PointerDeviceKind.mouse);
        tester.binding.handlePointerEvent(pointer.down(const Offset(150, 50)));
        tester.binding.handlePointerEvent(pointer.up());
        await tester.pump(const Duration(milliseconds: 50));
        tester.binding.handlePointerEvent(pointer.down(const Offset(150, 50)));
        tester.binding.handlePointerEvent(pointer.up());
        await tester.pump(const Duration(milliseconds: 100));

        expect(screenTaps, 1);
        expect(fake.seekCalls, isEmpty);
      },
    );
    testWidgets('long press boosts the rate and releasing restores', (
      tester,
    ) async {
      await pumpLayer(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PlayerGestureLayer)),
      );
      // 越过长按阈值（500ms）触发 boost，期间不移动以免被拖动手势抢占。
      await tester.pump(const Duration(milliseconds: 600));
      expect(boost.boosted, isTrue);

      await gesture.up();
      await tester.pump();
      expect(boost.boosted, isFalse);
    });
  });
}

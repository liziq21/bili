import 'dart:async';

import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:data/data.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';

import 'package:app/feature/video/common_widgets/player_keyboard_shortcuts.dart';

/// 假播放器：只实现快捷键路径需要的方法。
class _FakePlatformPlayer() extends Fake implements PlatformPlayer {
  final _position = StreamController<Duration>.broadcast(sync: true);
  final _duration = StreamController<Duration>.broadcast(sync: true);
  final _volume = StreamController<double>.broadcast(sync: true);
  final _rate = StreamController<double>.broadcast(sync: true);
  final List<Duration> seekCalls = [];
  final List<double> volumeCalls = [];
  final List<double> rateCalls = [];
  int playOrPauseCalls = 0;

  @override
  bool isVideoControllerAttached = false;

  @override
  PlayerStream get stream => PlayerStream(
    const Stream<Playlist>.empty(), // playlist
    const Stream<bool>.empty(), // playing
    const Stream<bool>.empty(), // completed
    _position.stream, // position
    _duration.stream, // duration
    _volume.stream, // volume
    _rate.stream, // rate
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
  }) async {}

  @override
  Future<void> playOrPause() async {
    playOrPauseCalls++;
  }

  @override
  Future<void> seek(Duration position) async {
    seekCalls.add(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    volumeCalls.add(volume);
    // 回发让 PlaybackState.volume 更新，连续按键才基于新值累加。
    // 假件在 PlatformPlayer 层，收到的已是 0..100 量程，直接回发。
    _volume.add(volume);
  }

  @override
  Future<void> setRate(double rate) async {
    rateCalls.add(rate);
    _rate.add(rate);
  }

  @override
  Future<void> dispose() async {}

  void emitPosition(Duration position) => _position.add(position);

  void emitDuration(Duration duration) => _duration.add(duration);
  void emitRate(double rate) => _rate.add(rate);

  void disposeStreams() {
    _position.close();
    _duration.close();
    _volume.close();
    _rate.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 有序浮点比较：media_kit 量程换算带 1e-14 级误差，逐项 closeTo。
  void expectVolumes(List<double> actual, List<double> expected) {
    expect(actual, hasLength(expected.length));
    for (var i = 0; i < expected.length; i++) {
      expect(actual[i], closeTo(expected[i], 0.01), reason: 'index $i');
    }
  }

  late _FakePlatformPlayer fake;
  late MediaPlaybackController controller;
  int fullscreenToggles = 0;

  setUp(() {
    fake = _FakePlatformPlayer();
    controller = MediaPlaybackController(fake);
    fullscreenToggles = 0;
  });

  tearDown(() {
    controller.dispose();
    fake.disposeStreams();
  });

  /// 只 pump 快捷键层，不经过原生 `Video` 与手势层。
  Future<void> pumpShortcuts(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerKeyboardShortcuts(
            controller: controller,
            onToggleFullscreen: () => fullscreenToggles++,
            child: const ColoredBox(
              color: Color(0xFF000000),
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await controller.openQueue([
      MediaStream(videoUrl: 'https://example.com/v.m4s'),
    ]);
    await tester.pump();
  }

  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(key);
    await tester.sendKeyUpEvent(key);
    await tester.pump();
  }

  testWidgets('space toggles playback', (tester) async {
    await pumpShortcuts(tester);

    await press(tester, LogicalKeyboardKey.space);

    expect(fake.playOrPauseCalls, 1);
  });

  testWidgets('arrow keys seek by 5 seconds', (tester) async {
    await pumpShortcuts(tester);
    fake.emitPosition(const Duration(seconds: 60));
    fake.emitDuration(const Duration(minutes: 10));
    await tester.pump();

    await press(tester, LogicalKeyboardKey.arrowRight);
    await press(tester, LogicalKeyboardKey.arrowLeft);

    expect(fake.seekCalls, contains(const Duration(seconds: 65)));
    expect(fake.seekCalls, contains(const Duration(seconds: 55)));
  });

  testWidgets('shift plus arrow seeks by 10 seconds', (tester) async {
    await pumpShortcuts(tester);
    fake.emitPosition(const Duration(seconds: 60));
    fake.emitDuration(const Duration(minutes: 10));
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await press(tester, LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    expect(fake.seekCalls, contains(const Duration(seconds: 70)));
  });

  testWidgets('seek is clamped to the media duration', (tester) async {
    await pumpShortcuts(tester);
    fake.emitPosition(const Duration(seconds: 595));
    fake.emitDuration(const Duration(minutes: 10));
    await tester.pump();

    await press(tester, LogicalKeyboardKey.arrowRight);

    expect(fake.seekCalls.last, const Duration(minutes: 10));
  });

  testWidgets('arrow up and down change the volume by a step', (tester) async {
    await pumpShortcuts(tester);

    // 从 1.0 先降两档，给升档留出空间。
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.arrowUp);

    expectVolumes(fake.volumeCalls, [95.0, 90.0, 95.0]);
  });

  testWidgets('volume never goes below zero', (tester) async {
    await pumpShortcuts(tester);

    for (var i = 0; i < 3; i++) {
      await press(tester, LogicalKeyboardKey.arrowDown);
    }

    expect(fake.volumeCalls.every((v) => v >= 0), isTrue);
    expectVolumes([fake.volumeCalls.last], [85.0]);
  });

  testWidgets('m mutes and restores the previous volume', (tester) async {
    await pumpShortcuts(tester);
    await press(tester, LogicalKeyboardKey.arrowDown);

    await press(tester, LogicalKeyboardKey.keyM);
    await press(tester, LogicalKeyboardKey.keyM);

    // 静音时置 0，再按恢复静音前的 0.95，而不是回到默认 1.0。
    expectVolumes(fake.volumeCalls, [95.0, 0.0, 95.0]);
  });

  testWidgets('f toggles fullscreen', (tester) async {
    await pumpShortcuts(tester);

    await press(tester, LogicalKeyboardKey.keyF);

    expect(fullscreenToggles, 1);
  });

  testWidgets('brackets step the playback rate', (tester) async {
    await pumpShortcuts(tester);
    fake.emitDuration(const Duration(minutes: 10));
    await tester.pump();

    await press(tester, LogicalKeyboardKey.bracketRight);
    await press(tester, LogicalKeyboardKey.bracketLeft);

    // 默认 1.0，升一档 1.25，再降回 1.0。
    expect(fake.rateCalls, containsAllInOrder([1.25, 1.0]));
  });

  testWidgets('brackets step from a rate outside the table', (tester) async {
    await pumpShortcuts(tester);
    fake.emitDuration(const Duration(minutes: 10));
    // 平台侧上报的倍速未必落在 kPlaybackRates 表内。
    fake.emitRate(0.6);
    await tester.pump();

    await press(tester, LogicalKeyboardKey.bracketRight);

    // 先落到 1.0 档，再按 delta 升一档；不是吞掉 delta 停在 1.0。
    expect(fake.rateCalls, containsAllInOrder([1.25]));
  });

  testWidgets('mouse wheel changes the volume', (tester) async {
    await pumpShortcuts(tester);

    final center = tester.getCenter(find.byType(PlayerKeyboardShortcuts));
    // 滚轮信号走 TestPointer：必须先 hover 建立指针位置，scroll 才带 hit
    // test 的坐标；直接构造 PointerScrollEvent 发给 binding 不做 hit test。
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    tester.binding.handlePointerEvent(pointer.hover(center));
    tester.binding.handlePointerEvent(pointer.scroll(const Offset(0, 100)));
    await tester.pump();
    tester.binding.handlePointerEvent(pointer.scroll(const Offset(0, -100)));
    await tester.pump();

    // 至少一次滚轮把音量调离 1.0，且始终在 0..1 内（浮点容差）。
    expect(fake.volumeCalls, isNotEmpty);
    expect(fake.volumeCalls.first, closeTo(95.0, 0.01));
    for (final v in fake.volumeCalls) {
      expect(v, inInclusiveRange(-0.01, 100.01));
    }
  });
}

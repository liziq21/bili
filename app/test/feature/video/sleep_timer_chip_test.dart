import 'dart:async';

import 'package:app/feature/video/common_widgets/sleep_timer_chip.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';

/// 假播放器：只实现睡眠定时器路径需要的方法。
class _FakePlatformPlayer extends Fake implements PlatformPlayer {
  final _playlist = StreamController<Playlist>.broadcast();
  final List<bool> pauseCalls = [];

  @override
  bool isVideoControllerAttached = false;

  @override
  PlayerStream get stream => PlayerStream(
    _playlist.stream, // playlist
    const Stream<bool>.empty(), // playing
    const Stream<bool>.empty(), // completed
    const Stream<Duration>.empty(), // position
    const Stream<Duration>.empty(), // duration
    const Stream<double>.empty(), // volume
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
  Future<void> pause() async {
    pauseCalls.add(true);
  }

  @override
  Future<void> setRate(double rate) async {}

  @override
  Future<void> dispose() async {}

  /// 发射队列状态：用于让「播完当前这条再停」观察到序号前进。
  void emitPlaylist({required int index, required int length}) {
    _playlist.add(
      Playlist(
        List.generate(length, (i) => Media('https://e.com/$i.m4s')),
        index: index,
      ),
    );
  }

  void disposeStreams() {
    _playlist.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePlatformPlayer fake;
  late MediaPlaybackController controller;

  setUp(() {
    fake = _FakePlatformPlayer();
    controller = MediaPlaybackController(fake);
  });

  tearDown(() {
    controller.dispose();
    fake.disposeStreams();
  });

  /// 直接 pump chip，不经过 `Video`：真 `VideoController` 在有 libmpv 的
  /// 环境会走原生 ffi，widget 测试里渲染它会段错误。
  Future<void> pumpChip(WidgetTester tester) async {
    // [MediaPlaybackController._subscribe] 由 openQueue 触发。
    await controller.openQueue([MediaStream(videoUrl: 'https://e.com/v.m4s')]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SleepTimerChip(controller: controller)),
      ),
    );
  }

  group('SleepTimerController', () {
    testWidgets('start sets the remaining duration', (tester) async {
      await pumpChip(tester);
      final sleep = SleepTimerController(controller);
      addTearDown(sleep.dispose);

      sleep.start(30);

      expect(sleep.remaining, const Duration(minutes: 30));
      expect(sleep.isActive, isTrue);
      expect(sleep.selectedMinutes, 30);
      // 测试体里显式停表：addTearDown 晚于 binding 的 pending-timer 检查。
      sleep.cancel();
    });

    testWidgets('cancel clears the remaining duration', (tester) async {
      await pumpChip(tester);
      final sleep = SleepTimerController(controller);
      addTearDown(sleep.dispose);

      sleep.start(15);
      sleep.cancel();

      expect(sleep.remaining, isNull);
      expect(sleep.isActive, isFalse);
      expect(sleep.selectedMinutes, isNull);
    });

    testWidgets('pauses the player when the countdown ends', (tester) async {
      await pumpChip(tester);
      final sleep = SleepTimerController(controller);
      addTearDown(sleep.dispose);

      sleep.start(1);
      // 单分钟档位 60 秒；推进 61 秒让最后一次 tick 落地。
      await tester.pump(const Duration(seconds: 61));

      expect(fake.pauseCalls, isNotEmpty);
      expect(sleep.isActive, isFalse);
      expect(sleep.remaining, isNull);
    });

    testWidgets('cancel stops the countdown before it fires', (tester) async {
      await pumpChip(tester);
      final sleep = SleepTimerController(controller);
      addTearDown(sleep.dispose);

      sleep.start(1);
      await tester.pump(const Duration(seconds: 30));
      sleep.cancel();
      await tester.pump(const Duration(seconds: 40));

      expect(fake.pauseCalls, isEmpty);
    });
  });

  /// 弹窗分两组共 9 项，默认 600px 视口只构建首屏，放大到能一次建全。
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
  }

  group('SleepTimerChip', () {
    testWidgets(
      'shows the idle label before starting and exposes accessible semantics',
      (tester) async {
        await pumpChip(tester);

        expect(find.text('Timer'), findsOneWidget);
        expect(find.bySemanticsLabel('Sleep timer Timer'), findsOneWidget);
      },
    );

    testWidgets('tapping the chip opens the picker with all durations', (
      tester,
    ) async {
      await pumpChip(tester);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();

      for (final minutes in ['15 min', '30 min', '45 min', '60 min']) {
        expect(find.text(minutes), findsOneWidget);
      }
    });

    testWidgets('selecting a duration shows the remaining time', (
      tester,
    ) async {
      await pumpChip(tester);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15 min'));
      await tester.pump();

      expect(find.text('15:00'), findsOneWidget);
    });

    testWidgets('a running timer offers a cancel entry', (tester) async {
      useTallViewport(tester);
      await pumpChip(tester);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('30 min'));
      await tester.pump();
      await tester.tap(find.text('30:00'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(find.text('Timer'), findsOneWidget);
    });
  });

  group('SleepTimerController after-current mode', () {
    testWidgets('does not pause when the countdown ends', (tester) async {
      await pumpChip(tester);
      final sleep = SleepTimerController(controller);
      addTearDown(sleep.dispose);
      await controller.openQueue([
        MediaStream(videoUrl: 'https://e.com/a.m4s'),
        MediaStream(videoUrl: 'https://e.com/b.m4s'),
      ]);
      fake.emitPlaylist(index: 0, length: 2);
      await tester.pump();

      sleep.start(1, action: SleepTimerAction.afterCurrent);
      await tester.pump(const Duration(seconds: 61));

      // 到点只标记待生效，不打断当前这条。
      expect(fake.pauseCalls, isEmpty);
      expect(sleep.pendingAfterCurrent, isTrue);
      expect(sleep.isActive, isTrue);
      sleep.cancel();
    });

    testWidgets('pauses once the queue advances to the next item', (
      tester,
    ) async {
      await pumpChip(tester);
      final sleep = SleepTimerController(controller);
      addTearDown(sleep.dispose);
      await controller.openQueue([
        MediaStream(videoUrl: 'https://e.com/a.m4s'),
        MediaStream(videoUrl: 'https://e.com/b.m4s'),
      ]);
      fake.emitPlaylist(index: 0, length: 2);
      await tester.pump();

      sleep.start(1, action: SleepTimerAction.afterCurrent);
      await tester.pump(const Duration(seconds: 61));
      expect(fake.pauseCalls, isEmpty);

      // 本条播完、队列要进下一条：此刻才停。
      fake.emitPlaylist(index: 1, length: 2);
      await tester.pump();

      expect(fake.pauseCalls, isNotEmpty);
      expect(sleep.pendingAfterCurrent, isFalse);
      sleep.cancel();
    });

    testWidgets('never pauses a single-item queue', (tester) async {
      await pumpChip(tester);
      final sleep = SleepTimerController(controller);
      addTearDown(sleep.dispose);
      await controller.openQueue([
        MediaStream(videoUrl: 'https://e.com/a.m4s'),
      ]);
      await tester.pump();

      sleep.start(1, action: SleepTimerAction.afterCurrent);
      await tester.pump(const Duration(seconds: 61));

      // 单条播放播完本就自然停，不该再插一次 pause（否则手动暂停会被误判）。
      expect(fake.pauseCalls, isEmpty);
      expect(sleep.pendingAfterCurrent, isTrue);
      sleep.cancel();
    });

    testWidgets('cancel clears the pending stop', (tester) async {
      await pumpChip(tester);
      final sleep = SleepTimerController(controller);
      addTearDown(sleep.dispose);
      sleep.start(1, action: SleepTimerAction.afterCurrent);
      await tester.pump(const Duration(seconds: 61));
      expect(sleep.pendingAfterCurrent, isTrue);

      sleep.cancel();

      expect(sleep.pendingAfterCurrent, isFalse);
      expect(sleep.isActive, isFalse);
    });
  });

  group('SleepTimerChip after-current picker', () {
    testWidgets('lists the after-current group below the pause group', (
      tester,
    ) async {
      useTallViewport(tester);
      await pumpChip(tester);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();

      expect(find.text('When time up'), findsOneWidget);
      expect(find.text('15 min (after current)'), findsOneWidget);
      // 两组各 4 个档位，同文案项取最后一个即 after-current 组。
      // 两组档位文案不再相同，第一组是裸的「15 分钟」。
      expect(find.text('15 min'), findsOneWidget);
      expect(find.text('15 min (after current)'), findsOneWidget);
    });

    testWidgets('after-current selection shows the pending label', (
      tester,
    ) async {
      useTallViewport(tester);
      await pumpChip(tester);
      await controller.openQueue([
        MediaStream(videoUrl: 'https://e.com/a.m4s'),
      ]);
      await tester.pump();

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15 min (after current)'));
      await tester.pumpAndSettle();
      expect(find.text('15:00'), findsOneWidget);

      // 15 分钟档 = 900s，推进 901s 让最后一次 tick 落地。
      await tester.pump(const Duration(seconds: 901));
      await tester.pump();

      expect(find.text('After current'), findsOneWidget);
    });
  });
}

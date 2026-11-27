import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/domain/sleep_timer_action.dart';
import 'package:app/feature/notification/sleep_timer_notifier.dart';
import 'package:app/feature/video/common_widgets/sleep_timer_chip.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// 假播放器：只实现睡眠定时器路径需要的方法。
class _FakePlatformPlayer() extends Fake implements PlatformPlayer {
  final _playlist = StreamController<Playlist>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final List<bool> pauseCalls = [];

  @override
  bool isVideoControllerAttached = false;

  @override
  PlayerStream get stream => PlayerStream(
    _playlist.stream, // playlist
    _playing.stream, // playing
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
    _playing.add(play);
  }

  @override
  Future<void> pause() async {
    pauseCalls.add(true);
    _playing.add(false);
  }

  @override
  Future<void> play() async {
    _playing.add(true);
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
    _playing.close();
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
  Future<void> pumpChip(
    WidgetTester tester, {
    PreferencesDataSource? preferences,
    SleepTimerNotifier? notifier,
    VoidCallback? onExit,
  }) async {
    // [MediaPlaybackController._subscribe] 由 openQueue 触发。
    await controller.openQueue([MediaStream(videoUrl: 'https://e.com/v.m4s')]);
    Widget child = MaterialApp(
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SleepTimerChip(controller: controller, onExit: onExit),
      ),
    );
    if (preferences != null) {
      child = Provider<PreferencesDataSource>.value(
        value: preferences,
        child: child,
      );
    }
    if (notifier != null) {
      child = Provider<SleepTimerNotifier>.value(value: notifier, child: child);
    }
    await tester.pumpWidget(child);
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

  /// 弹窗有行为选项、六个档位和自定义项，默认 600px 视口只构建首屏，放大到能一次建全。
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

    testWidgets('the sheet title aligns with the option text', (tester) async {
      useTallViewport(tester);
      await pumpChip(tester);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();

      final titleX = tester.getTopLeft(find.text('Sleep timer')).dx;
      final optionX = tester.getTopLeft(find.text('Pause now')).dx;
      expect((titleX - optionX).abs(), lessThan(0.5));
    });

    testWidgets('the chip opens the picker from a screen-reader tap action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpChip(tester);

      final node = tester.getSemantics(
        find.bySemanticsLabel('Sleep timer Timer'),
      );
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pumpAndSettle();

      expect(find.text('Sleep timer'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('starts the configured default timer on player entry', (
      tester,
    ) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final preferences = PreferencesDataSource(
        sharedPreferences: SharedPreferencesAsync(),
      );
      addTearDown(preferences.dispose);
      await preferences.set(PreferencesKey.sleepTimerDefaultMinutes, 15);

      await pumpChip(tester, preferences: preferences);
      await tester.pump();

      expect(find.text('15:00'), findsOneWidget);
    });

    testWidgets('keeps the default action when no default timer is set', (
      tester,
    ) async {
      useTallViewport(tester);
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final preferences = PreferencesDataSource(
        sharedPreferences: SharedPreferencesAsync(),
      );
      addTearDown(preferences.dispose);
      await preferences.set(
        PreferencesKey.sleepTimerDefaultAction,
        'exitPlayer',
      );

      await pumpChip(tester, preferences: preferences);
      await tester.pump();

      // 默认档位为 0 时不自动开始，但弹窗里的行为选择应跟随持久化默认值。
      expect(find.text('Timer'), findsOneWidget);
      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();

      ListTile tileFor(String label) => tester.widget<ListTile>(
        find.ancestor(of: find.text(label), matching: find.byType(ListTile)),
      );
      expect(tileFor('Close player').trailing, isNotNull);
      expect(tileFor('Pause now').trailing, isNull);
    });

    testWidgets('defaults to pausing when the countdown ends', (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final preferences = PreferencesDataSource(
        sharedPreferences: SharedPreferencesAsync(),
      );
      addTearDown(preferences.dispose);
      await preferences.set(PreferencesKey.sleepTimerDefaultMinutes, 1);

      await pumpChip(tester, preferences: preferences);
      await tester.pump();
      await tester.pump();

      expect(find.text('01:00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));

      expect(fake.pauseCalls, isNotEmpty);
    });

    testWidgets('applies the configured after-current default action', (
      tester,
    ) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final preferences = PreferencesDataSource(
        sharedPreferences: SharedPreferencesAsync(),
      );
      addTearDown(preferences.dispose);
      await preferences.set(PreferencesKey.sleepTimerDefaultMinutes, 1);
      await preferences.set(PreferencesKey.sleepTimerDefaultAfterCurrent, true);

      await pumpChip(tester, preferences: preferences);
      await tester.pump();
      await tester.pump();
      await controller.openQueue([
        MediaStream(videoUrl: 'https://e.com/a.m4s'),
        MediaStream(videoUrl: 'https://e.com/b.m4s'),
      ]);
      fake.emitPlaylist(index: 0, length: 2);
      await tester.pump();

      expect(find.text('01:00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));

      // after-current 默认值：归零时不打断当前条目。
      expect(fake.pauseCalls, isEmpty);

      fake.emitPlaylist(index: 1, length: 2);
      await tester.pump();

      expect(fake.pauseCalls, isNotEmpty);
    });

    testWidgets('tapping the chip opens the picker with all durations', (
      tester,
    ) async {
      useTallViewport(tester);
      await pumpChip(tester);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();

      for (final minutes in [
        '10 min',
        '20 min',
        '30 min',
        '60 min',
        '90 min',
        '120 min',
      ]) {
        expect(find.text(minutes), findsOneWidget);
      }
      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('selecting a duration shows the remaining time', (
      tester,
    ) async {
      await pumpChip(tester);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10 min'));
      await tester.pump();

      expect(find.text('10:00'), findsOneWidget);
    });

    testWidgets('accepts a custom duration in minutes', (tester) async {
      useTallViewport(tester);
      await pumpChip(tester);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom').first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '37');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('37:00'), findsOneWidget);
    });

    testWidgets('rejects a custom duration outside the supported range', (
      tester,
    ) async {
      useTallViewport(tester);
      await pumpChip(tester);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom').first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1441');
      await tester.tap(find.text('OK'));
      await tester.pump();

      expect(
        find.text('Enter a duration from 1 to 1440 minutes.'),
        findsOneWidget,
      );
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

      expect(find.text('Cancel timer'), findsOneWidget);
      await tester.tap(find.text('Cancel timer'));
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

  group('SleepTimerChip action picker', () {
    testWidgets('lists every ending action and the duration list', (
      tester,
    ) async {
      useTallViewport(tester);
      await pumpChip(tester);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();

      expect(find.text('When the sleep timer ends'), findsOneWidget);
      expect(find.text('Pause now'), findsOneWidget);
      expect(find.text('After current video'), findsOneWidget);
      expect(find.text('Close player'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('10 min'), findsOneWidget);
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
      await tester.tap(find.text('After current video'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10 min'));
      await tester.pumpAndSettle();
      expect(find.text('10:00'), findsOneWidget);

      // 10 分钟档 = 600s，推进 601s 让最后一次 tick 落地。
      await tester.pump(const Duration(seconds: 601));
      await tester.pump();

      expect(find.text('After current'), findsOneWidget);
    });

    testWidgets('close-player selection pauses and exits the player', (
      tester,
    ) async {
      useTallViewport(tester);
      var exitCalls = 0;
      await pumpChip(tester, onExit: () => exitCalls++);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close player'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10 min'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 601));

      expect(fake.pauseCalls, isNotEmpty);
      expect(exitCalls, 1);
    });

    testWidgets('requests notification permission once per session', (
      tester,
    ) async {
      useTallViewport(tester);
      final notifier = _RecordingSleepTimerNotifier();
      await pumpChip(tester, notifier: notifier);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10 min'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('10:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20 min'));
      await tester.pumpAndSettle();

      expect(notifier.permissionRequests, 1);
    });

    testWidgets('after-current selection does not request permission', (
      tester,
    ) async {
      useTallViewport(tester);
      final notifier = _RecordingSleepTimerNotifier();
      await pumpChip(tester, notifier: notifier);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('After current video'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10 min'));
      await tester.pumpAndSettle();

      // afterCurrent 不发「即将停止播放」提醒，不该弹权限框。
      expect(notifier.permissionRequests, 0);
    });

    testWidgets('cancelling the timer dismisses the ending-soon warning', (
      tester,
    ) async {
      useTallViewport(tester);
      final notifier = _RecordingSleepTimerNotifier();
      await pumpChip(tester, notifier: notifier);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10 min'));
      await tester.pumpAndSettle();

      // 进入最后一分钟，提醒先发出，再取消。
      await tester.pump(const Duration(seconds: 541));
      await tester.pump();
      expect(notifier.endingSoonCalls, 1);
      expect(find.text('00:59'), findsOneWidget);

      await tester.tap(find.text('00:59'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel timer'));
      await tester.pumpAndSettle();

      expect(notifier.cancelCalls, 1);
      expect(notifier.canceledIds, [notifier.endingSoonIds.single]);
      expect(find.text('Timer'), findsOneWidget);
    });
  });

  group('SleepTimerScope', () {
    testWidgets('keeps the countdown when the control bar is rebuilt', (
      tester,
    ) async {
      await controller.openQueue([
        MediaStream(videoUrl: 'https://e.com/v.m4s'),
      ]);
      final timer = SleepTimerController(controller);
      addTearDown(timer.dispose);

      Widget build(Key chipKey) => MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SleepTimerScope(
            controller: timer,
            defaultAction: SleepTimerAction.pauseNow,
            onTimerStarted: (_) {},
            child: SleepTimerChip(key: chipKey, controller: controller),
          ),
        ),
      );

      await tester.pumpWidget(build(const ValueKey('first')));
      timer.start(10);
      await tester.pump();
      expect(find.text('10:00'), findsOneWidget);

      // 全屏切换 / 控制栏自动隐藏会重建按钮；倒计时属于播放器，不属于按钮。
      await tester.pumpWidget(build(const ValueKey('second')));
      await tester.pump();

      expect(find.text('10:00'), findsOneWidget);
      expect(timer.isActive, isTrue);
      timer.cancel();
    });
  });

  group('SleepTimerController ending-soon warning', () {
    testWidgets('fires once when a longer timer enters the last minute', (
      tester,
    ) async {
      await pumpChip(tester);
      var warnings = 0;
      final sleep = SleepTimerController(
        controller,
        onEndingSoon: () async => warnings++,
      );
      addTearDown(sleep.dispose);

      sleep.start(2);
      await tester.pump(const Duration(seconds: 61));
      expect(warnings, 1);

      await tester.pump(const Duration(seconds: 60));
      expect(warnings, 1);
      sleep.cancel();
    });

    testWidgets('does not warn for the after-current action', (tester) async {
      await pumpChip(tester);
      var warnings = 0;
      final sleep = SleepTimerController(
        controller,
        onEndingSoon: () async => warnings++,
      );
      addTearDown(sleep.dispose);

      sleep.start(2, action: SleepTimerAction.afterCurrent);
      await tester.pump(const Duration(seconds: 61));

      expect(warnings, 0);
      sleep.cancel();
    });

    testWidgets('skips the warning for a one-minute timer', (tester) async {
      await pumpChip(tester);
      var warnings = 0;
      final sleep = SleepTimerController(
        controller,
        onEndingSoon: () async => warnings++,
      );
      addTearDown(sleep.dispose);

      sleep.start(1);
      await tester.pump(const Duration(seconds: 61));

      expect(warnings, 0);
      expect(fake.pauseCalls, isNotEmpty);
    });

    testWidgets('does not warn late when the crossing happens while paused', (
      tester,
    ) async {
      await pumpChip(tester);
      var warnings = 0;
      final sleep = SleepTimerController(
        controller,
        onEndingSoon: () async => warnings++,
      );
      addTearDown(sleep.dispose);

      sleep.start(2);
      // 90 秒时暂停，越过最后一分钟，再在 50 秒时恢复播放。
      await tester.pump(const Duration(seconds: 30));
      await controller.pause();
      await tester.pump(const Duration(seconds: 40));
      await controller.play();
      await tester.pump(const Duration(seconds: 10));

      // 恢复后剩余已不足一分钟，此时再提醒「一分钟后停止」是假消息。
      expect(warnings, 0);
      sleep.cancel();
    });

    testWidgets('routes the warning to the notifier', (tester) async {
      useTallViewport(tester);
      final notifier = _RecordingSleepTimerNotifier();
      await pumpChip(tester, notifier: notifier);

      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10 min'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 541));

      expect(notifier.endingSoonCalls, 1);
    });
  });
}

class _RecordingSleepTimerNotifier() implements SleepTimerNotifier {
  int permissionRequests = 0;
  int endingSoonCalls = 0;
  int cancelCalls = 0;
  final List<int> endingSoonIds = [];
  final List<int> canceledIds = [];

  @override
  Future<void> requestPermission() async {
    permissionRequests++;
  }

  @override
  Future<void> notifyEndingSoon({
    int id = defaultSleepTimerNotificationId,
  }) async {
    endingSoonCalls++;
    endingSoonIds.add(id);
  }

  @override
  Future<void> cancel({int id = defaultSleepTimerNotificationId}) async {
    cancelCalls++;
    canceledIds.add(id);
  }
}

import 'dart:async';

import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/video/common_widgets/playback_speed_chip.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:data/data.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:model/model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// 假播放器：只实现倍速路径需要的方法。
class _FakePlatformPlayer extends Fake implements PlatformPlayer {
  final _rate = StreamController<double>.broadcast();
  final _playlist = StreamController<Playlist>.broadcast();
  final List<double> rateCalls = [];

  /// VideoController 构造体同步写入此字段。
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
  }) async {
    if (playable is Playlist) _playlist.add(playable);
  }

  @override
  Future<void> setRate(double rate) async {
    rateCalls.add(rate);
    _rate.add(rate);
  }

  @override
  Future<void> dispose() async {}

  void disposeStreams() {
    _rate.close();
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

  /// [_subscribe] 由 [openQueue] 触发：不打开队列，rate 事件无人监听。
  Future<void> openForRateEvents() async {
    await controller.openQueue([MediaStream(videoUrl: 'https://e.com/v.m4s')]);
  }

  tearDown(() {
    controller.dispose();
    fake.disposeStreams();
  });

  /// 直接 pump chip，不经过 `Video`：真 `VideoController` 在有 libmpv 的
  /// 环境会走原生 ffi，widget 测试里渲染它会段错误。
  Future<void> pumpChip(
    WidgetTester tester, {
    PreferencesDataSource? preferences,
  }) async {
    // [_subscribe] 由 [openQueue] 触发：不打开队列，rate 事件无人监听。
    await controller.openQueue([MediaStream(videoUrl: 'https://e.com/v.m4s')]);

    // material_ui 的控件需要它自己的 MaterialApp 提供 localizations。
    Widget child = MaterialApp(
      home: Scaffold(body: PlaybackSpeedChip(controller: controller)),
    );
    if (preferences != null) {
      child = RepositoryProvider<PreferencesDataSource>.value(
        value: preferences,
        child: child,
      );
    }
    await tester.pumpWidget(child);
  }

  group('rateLabel', () {
    test('trims trailing zeros', () {
      expect(rateLabel(1.0), '1x');
      expect(rateLabel(1.5), '1.5x');
      expect(rateLabel(0.75), '0.75x');
      expect(rateLabel(2.0), '2x');
      expect(rateLabel(0.5), '0.5x');
    });
  });

  group('PlaybackSpeedChip', () {
    testWidgets('shows 1x before any selection', (tester) async {
      await pumpChip(tester);

      expect(find.text('1x'), findsOneWidget);
    });

    testWidgets('updates the label when the rate changes', (tester) async {
      await pumpChip(tester);

      await controller.setRate(1.5);
      await tester.pump();

      expect(find.text('1.5x'), findsOneWidget);
    });

    testWidgets('tapping the chip opens the picker with all rates', (
      tester,
    ) async {
      await pumpChip(tester);

      await tester.tap(find.text('1x'));
      await tester.pumpAndSettle();

      expect(find.text('倍速'), findsOneWidget);
      // 底部条目可能落在视口外（默认测口 800x600），滚进来再断言。
      await tester.scrollUntilVisible(
        find.text('2x'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      for (final label in [
        '0.5x',
        '0.75x',
        '1x',
        '1.25x',
        '1.5x',
        '1.75x',
        '2x',
      ]) {
        expect(find.text(label), findsWidgets);
      }
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('selecting a rate applies it and closes the picker', (
      tester,
    ) async {
      await pumpChip(tester);

      await tester.tap(find.text('1x'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('1.5x'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('1.5x').last);
      await tester.pumpAndSettle();

      expect(find.text('1.5x'), findsOneWidget);
      expect(fake.rateCalls, contains(1.5));
      // 选择器已关闭：只剩 chip 自身。
      expect(find.text('0.5x'), findsNothing);
    });

    testWidgets('persists the selected rate when a data source is injected', (
      tester,
    ) async {
      final inMemory = InMemorySharedPreferencesAsync.empty();
      SharedPreferencesAsyncPlatform.instance = inMemory;
      final preferences = PreferencesDataSource(
        sharedPreferences: SharedPreferencesAsync(),
      );
      addTearDown(preferences.dispose);

      await pumpChip(tester, preferences: preferences);

      await tester.tap(find.text('1x'));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('1.75x'),
        find.byType(Scrollable).last,
        const Offset(0, -100),
      );
      await tester.pump();
      await tester.tap(find.text('1.75x').last);
      await tester.pump();
      await tester.pumpAndSettle();

      final stored = await preferences.get(PreferencesKey.playbackRate);
      expect(stored.isOk, isTrue);
      expect((stored as Ok<double>).value, 1.75);
    });

    testWidgets('does not persist without an injected data source', (
      tester,
    ) async {
      await pumpChip(tester);

      await tester.tap(find.text('1x'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('1.25x'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('1.25x').last);
      await tester.pumpAndSettle();

      // 套用照常生效，持久化被跳过（不抛异常即通过）。
      expect(fake.rateCalls, contains(1.25));
    });
  });

  group('BoostRateController', () {
    test('long-press switches to the boost rate', () async {
      await openForRateEvents();
      final boost = BoostRateController(controller);
      addTearDown(boost.dispose);

      boost.onLongPress();
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.rate, 2.0);
      expect(boost.boosted, isTrue);
    });

    test('releasing restores the previous rate', () async {
      await openForRateEvents();
      final boost = BoostRateController(controller);
      addTearDown(boost.dispose);

      await controller.setRate(1.25);
      boost.onLongPress();
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.rate, 2.0);

      boost.onLongPressEnd();
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.rate, 1.25);
      expect(boost.boosted, isFalse);
    });

    test('notifies listeners on press and release', () {
      final boost = BoostRateController(controller);
      addTearDown(boost.dispose);

      var notifications = 0;
      boost.addListener(() => notifications++);

      boost.onLongPress();
      boost.onLongPressEnd();

      expect(notifications, 2);
    });
  });
}

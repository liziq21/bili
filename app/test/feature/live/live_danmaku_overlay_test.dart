import 'dart:async';

import 'package:app/data/repository/danmaku_repository.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/live/live_danmaku_overlay.dart';
import 'package:app/feature/video/danmaku/danmaku_painter.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:clock/clock.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart' show Result;
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _FakePlaybackController() implements MediaPlaybackController {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDanmakuRepository() implements DanmakuRepository {
  final Map<int, StreamController<DanmakuComment>> _controllers = {};
  final List<int> requestedRooms = [];

  StreamController<DanmakuComment> controllerFor(int roomId) => _controllers
      .putIfAbsent(roomId, () => StreamController<DanmakuComment>.broadcast());

  @override
  Stream<DanmakuComment> liveDanmaku(int roomId) {
    requestedRooms.add(roomId);
    return controllerFor(roomId).stream;
  }

  @override
  Future<Result<List<DanmakuComment>, Exception>> getDanmaku(
    String videoId,
  ) async => const Result.success(<DanmakuComment>[]);
}

DanmakuComment _comment(String content) => DanmakuComment(
  startTime: Duration.zero,
  mode: DanmakuMode.scrolling,
  fontSize: 25,
  colorArgb: 0xFFFFFF,
  content: content,
);

/// Only the painter whose delegate is [DanmakuPainter] belongs to the overlay;
/// MaterialApp and Scaffold paint through their own [CustomPaint] widgets.
final _overlayPainter = find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.painter is DanmakuPainter,
);

DanmakuPainter _painterOf(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(_overlayPainter);
  return paint.painter! as DanmakuPainter;
}

LiveDanmakuOverlayState _overlayState(WidgetTester tester) =>
    tester.state<LiveDanmakuOverlayState>(find.byType(LiveDanmakuOverlay));

/// Advances the fake clock by [span] without drawing, then reports whether
/// anything scheduled a frame.
///
/// A timer that keeps calling `setState` at 20 Hz leaves a frame scheduled; a
/// stopped timer leaves none.
Future<bool> _schedulesFrameWithin(WidgetTester tester, Duration span) async {
  await tester.binding.delayed(span);
  final scheduled = tester.binding.hasScheduledFrame;
  await tester.pump();
  return scheduled;
}

void main() {
  late _FakeDanmakuRepository repository;
  late PreferencesDataSource preferences;
  late MediaPlaybackController controller;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    repository = _FakeDanmakuRepository();
    preferences = PreferencesDataSource();
    controller = _FakePlaybackController();
  });

  tearDown(() {
    preferences.dispose();
    for (final room in repository.requestedRooms.toSet()) {
      repository.controllerFor(room).close();
    }
  });

  Widget appFor(int roomId) => MaterialApp(
    localizationsDelegates: const [
      ...AppLocalizations.localizationsDelegates,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Provider<PreferencesDataSource>.value(
      value: preferences,
      child: Provider<DanmakuRepository>.value(
        value: repository,
        child: Scaffold(
          body: Stack(
            children: [
              LiveDanmakuOverlay(controller: controller, roomId: roomId),
            ],
          ),
        ),
      ),
    ),
  );

  testWidgets('renders an incoming live danmaku comment', (tester) async {
    await tester.pumpWidget(appFor(7));
    await tester.pumpAndSettle();

    repository.controllerFor(7).add(_comment('hello live'));
    await tester.pump();
    await tester.pump();

    expect(
      _painterOf(tester).comments.map((c) => c.content),
      contains('hello live'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('cancels the repository subscription when disposed', (
    tester,
  ) async {
    await tester.pumpWidget(appFor(7));
    await tester.pumpAndSettle();

    expect(repository.controllerFor(7).hasListener, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(repository.controllerFor(7).hasListener, isFalse);
  });

  testWidgets('resubscribes and clears comments when the room changes', (
    tester,
  ) async {
    await tester.pumpWidget(appFor(7));
    await tester.pumpAndSettle();

    repository.controllerFor(7).add(_comment('room seven'));
    await tester.pump();
    await tester.pump();
    expect(
      _painterOf(tester).comments.map((c) => c.content),
      contains('room seven'),
    );

    await tester.pumpWidget(appFor(8));
    await tester.pump();

    expect(repository.controllerFor(7).hasListener, isFalse);
    expect(repository.controllerFor(8).hasListener, isTrue);
    // Comments from the previous room must not leak into the new room.
    expect(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is DanmakuPainter,
      ),
      findsNothing,
    );

    repository.controllerFor(8).add(_comment('room eight'));
    await tester.pump();
    await tester.pump();

    final contents = _painterOf(tester).comments.map((c) => c.content);
    expect(contents, contains('room eight'));
    expect(contents, isNot(contains('room seven')));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('stops repainting once the last comment scrolls out', (
    tester,
  ) async {
    await withClock(tester.binding.clock, () async {
      await tester.pumpWidget(appFor(7));
      await tester.pumpAndSettle();

      repository.controllerFor(7).add(_comment('short lived'));
      await tester.pump();
      await tester.pump();
      expect(_overlayPainter, findsOneWidget);

      // The default scroll duration is 8s: the comment is still on screen well
      // before that, and gone shortly after it.
      await tester.pump(const Duration(seconds: 5));
      expect(_overlayPainter, findsOneWidget);
      expect(_overlayState(tester).isTickerRunning, isTrue);

      await tester.pump(const Duration(seconds: 4));
      expect(_overlayPainter, findsNothing);
      expect(_overlayState(tester).isTickerRunning, isFalse);
      expect(
        await _schedulesFrameWithin(tester, const Duration(milliseconds: 200)),
        isFalse,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets('keeps the lane history while a comment is still scrolling', (
    tester,
  ) async {
    await withClock(tester.binding.clock, () async {
      await tester.pumpWidget(appFor(7));
      await tester.pumpAndSettle();

      repository.controllerFor(7).add(_comment('first'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      repository.controllerFor(7).add(_comment('second'));
      await tester.pump();
      await tester.pump();
      final comments = _painterOf(tester).comments;

      // At 10.5s the first comment has left the screen but the second one is
      // still scrolling until 11s. Rebuilding the timeline from a pruned list
      // here would hand the second comment a different lane mid-scroll, so the
      // overlay must keep passing the same list instance to the painter.
      await tester.pump(const Duration(milliseconds: 7500));

      expect(_painterOf(tester).comments, same(comments));

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets('stops repainting when danmaku is switched off', (tester) async {
    await withClock(tester.binding.clock, () async {
      await tester.pumpWidget(appFor(7));
      await tester.pumpAndSettle();

      repository.controllerFor(7).add(_comment('still on screen'));
      await tester.pump();
      await tester.pump();
      expect(_overlayPainter, findsOneWidget);

      await preferences.set(PreferencesKey.danmakuEnabled, false);
      await tester.pump();
      await tester.pump();

      expect(_overlayPainter, findsNothing);
      expect(_overlayState(tester).isTickerRunning, isFalse);
      expect(
        await _schedulesFrameWithin(tester, const Duration(milliseconds: 200)),
        isFalse,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}

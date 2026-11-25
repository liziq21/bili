import 'dart:async';

import 'package:app/data/repository/danmaku_repository.dart';
import 'package:app/datastore/preferences_data_source.dart';
import 'package:app/feature/video/danmaku/danmaku_overlay.dart';
import 'package:app/feature/video/danmaku/danmaku_painter.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart' show Result;
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class _FakeDanmakuRepository() implements DanmakuRepository {
  Result<List<DanmakuComment>, Exception> result = const Result.success(
    <DanmakuComment>[],
  );
  final List<String> requestedVideoIds = [];

  @override
  Future<Result<List<DanmakuComment>, Exception>> getDanmaku(
    String videoId,
  ) async {
    requestedVideoIds.add(videoId);
    return result;
  }

  @override
  Stream<DanmakuComment> liveDanmaku(int roomId) => const Stream.empty();
}

final class _FakePlaybackController() implements MediaPlaybackController {
  final _states = StreamController<PlaybackState>.broadcast();

  @override
  PlaybackState state = const PlaybackState(
    isPlaying: false,
    isBuffering: false,
    position: Duration.zero,
    duration: Duration.zero,
  );

  @override
  Stream<PlaybackState> get states => _states.stream;

  void emit(PlaybackState next) {
    state = next;
    _states.add(next);
  }

  void close() => _states.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DanmakuComment _comment(String content) => DanmakuComment(
  startTime: Duration.zero,
  mode: DanmakuMode.scrolling,
  fontSize: 25,
  colorArgb: 0xFFFFFF,
  content: content,
);

final _painterFinder = find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.painter is DanmakuPainter,
);

DanmakuPainter _painterOf(WidgetTester tester) =>
    tester.widget<CustomPaint>(_painterFinder).painter! as DanmakuPainter;

void main() {
  late _FakeDanmakuRepository repository;
  late _FakePlaybackController controller;
  late PreferencesDataSource preferences;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    repository = _FakeDanmakuRepository();
    controller = _FakePlaybackController();
    preferences = PreferencesDataSource();
  });

  tearDown(() {
    preferences.dispose();
    controller.close();
  });

  Widget appFor(String videoId) => MaterialApp(
    locale: const Locale('en'),
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
              DanmakuOverlay(controller: controller, videoId: videoId),
            ],
          ),
        ),
      ),
    ),
  );

  testWidgets('loads comments for the requested video into the painter', (
    tester,
  ) async {
    // Given a source that returns one comment for BV1.
    repository.result = Result.success([_comment('hello video')]);

    // When the overlay opens for BV1.
    await tester.pumpWidget(appFor('BV1'));
    await tester.pumpAndSettle();

    // Then it requests BV1 and hands the comment to the painter.
    expect(repository.requestedVideoIds, ['BV1']);
    expect(
      _painterOf(tester).comments.map((comment) => comment.content),
      contains('hello video'),
    );
    // The painter caches by list identity, so the overlay must pass a snapshot.
    expect(
      () => _painterOf(tester).comments.add(_comment('mutated')),
      throwsUnsupportedError,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('hides the overlay when danmaku are disabled', (tester) async {
    // Given danmaku switched off in preferences and a source that has comments.
    await preferences.set(PreferencesKey.danmakuEnabled, false);
    repository.result = Result.success([_comment('hidden')]);

    // When the overlay opens.
    await tester.pumpWidget(appFor('BV1'));
    await tester.pumpAndSettle();

    // Then no painter is mounted at all.
    expect(_painterFinder, findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reacts when danmaku are toggled while playing', (tester) async {
    // Given an overlay showing comments with danmaku enabled.
    repository.result = Result.success([_comment('live setting')]);
    await tester.pumpWidget(appFor('BV1'));
    await tester.pumpAndSettle();
    expect(_painterFinder, findsOneWidget);

    // When the user turns danmaku off from the settings page.
    await preferences.set(PreferencesKey.danmakuEnabled, false);
    await tester.pumpAndSettle();

    // Then the overlay disappears without reloading the video.
    expect(_painterFinder, findsNothing);

    // When they turn it back on.
    await preferences.set(PreferencesKey.danmakuEnabled, true);
    await tester.pumpAndSettle();

    // Then the same comments are shown again and BV1 was only fetched once.
    expect(_painterFinder, findsOneWidget);
    expect(repository.requestedVideoIds, ['BV1']);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('applies display settings without refetching comments', (
    tester,
  ) async {
    // Given an overlay showing comments with the default font size.
    repository.result = Result.success([_comment('style')]);
    await tester.pumpWidget(appFor('BV1'));
    await tester.pumpAndSettle();
    expect(_painterOf(tester).settings.fontSize, 18);

    // When the user changes the font size from the settings page.
    await preferences.set(PreferencesKey.danmakuFontSize, 30.0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();
    await tester.pump();

    // Then the mounted painter picks it up without reloading the comments.
    expect(_painterOf(tester).settings.fontSize, 30.0);
    expect(repository.requestedVideoIds, ['BV1']);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('renders nothing when the source has no comments', (
    tester,
  ) async {
    // Given a source that returns an empty list.
    repository.result = const Result.success(<DanmakuComment>[]);

    // When the overlay opens.
    await tester.pumpWidget(appFor('BV1'));
    await tester.pumpAndSettle();

    // Then it mounts no painter.
    expect(_painterFinder, findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('renders nothing when loading the comments fails', (
    tester,
  ) async {
    // Given a source that fails.
    repository.result = Result.error(Exception('network down'));

    // When the overlay opens.
    await tester.pumpWidget(appFor('BV1'));
    await tester.pumpAndSettle();

    // Then the failure is swallowed and no painter is mounted.
    expect(_painterFinder, findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('follows playback position updates', (tester) async {
    // Given an overlay showing one comment.
    repository.result = Result.success([_comment('moving')]);
    await tester.pumpWidget(appFor('BV1'));
    await tester.pumpAndSettle();
    final cache = _painterOf(tester).cache;

    // When playback advances to three seconds.
    controller.emit(
      const PlaybackState(
        isPlaying: true,
        isBuffering: false,
        position: Duration(seconds: 3),
        duration: Duration(minutes: 1),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Then the painter renders at the new position and keeps its cache.
    expect(_painterOf(tester).position, const Duration(seconds: 3));
    expect(_painterOf(tester).cache, same(cache));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('skips rebuilds when only non-position fields change', (
    tester,
  ) async {
    // Given an overlay showing one comment at position zero.
    repository.result = Result.success([_comment('steady')]);
    await tester.pumpWidget(appFor('BV1'));
    await tester.pumpAndSettle();
    final painter = _painterOf(tester);

    // When playback reports a new state without moving the position.
    controller.emit(
      const PlaybackState(
        isPlaying: true,
        isBuffering: false,
        position: Duration.zero,
        duration: Duration(minutes: 1),
      ),
    );
    await tester.pump();

    // Then the overlay does not rebuild the painter for nothing.
    expect(identical(_painterOf(tester), painter), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reloads comments when the video changes', (tester) async {
    // Given BV1 loaded with its own comment.
    repository.result = Result.success([_comment('first video')]);
    await tester.pumpWidget(appFor('BV1'));
    await tester.pumpAndSettle();
    expect(
      _painterOf(tester).comments.map((comment) => comment.content),
      contains('first video'),
    );

    // When the overlay switches to BV2, which has a different comment.
    repository.result = Result.success([_comment('second video')]);
    await tester.pumpWidget(appFor('BV2'));
    await tester.pumpAndSettle();

    // Then BV2 is requested and only its comments remain.
    expect(repository.requestedVideoIds, ['BV1', 'BV2']);
    final contents = _painterOf(tester).comments
        .map((comment) => comment.content);
    expect(contents, contains('second video'));
    expect(contents, isNot(contains('first video')));

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

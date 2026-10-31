import 'dart:async';

import 'package:app/data/repository/app_live_room_repository.dart';
import 'package:app/feature/live/live_screen.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:model/model.dart';
import 'package:provider/provider.dart';

class _FakePlatformPlayer() extends Fake implements PlatformPlayer {
  final _playing = StreamController<bool>.broadcast();
  final _playlist = StreamController<Playlist>.broadcast();

  @override
  bool isVideoControllerAttached = false;

  @override
  PlayerStream get stream => PlayerStream(
    _playlist.stream,
    _playing.stream,
    const Stream<bool>.empty(),
    const Stream<Duration>.empty(),
    const Stream<Duration>.empty(),
    const Stream<double>.empty(),
    const Stream<double>.empty(),
    const Stream<double>.empty(),
    const Stream<bool>.empty(),
    const Stream<double>.empty(),
    const Stream<Duration>.empty(),
    const Stream<PlaylistMode>.empty(),
    const Stream<bool>.empty(),
    const Stream<AudioParams>.empty(),
    const Stream<VideoParams>.empty(),
    const Stream<double?>.empty(),
    const Stream<AudioDevice>.empty(),
    const Stream<List<AudioDevice>>.empty(),
    const Stream<Track>.empty(),
    const Stream<Tracks>.empty(),
    const Stream<int?>.empty(),
    const Stream<int?>.empty(),
    const Stream<List<String>>.empty(),
    const Stream<PlayerLog>.empty(),
    const Stream<String>.empty(),
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
  Future<void> dispose() async {}

  void disposeStreams() {
    _playing.close();
    _playlist.close();
  }
}

class _FakeLiveDataSource extends LiveRoomDetailRemoteDataSource {
  @override
  String get sourceId => 'fake';

  @override
  Future<Result<LiveRoomDetail, Exception>> getLiveRoomDetail(
    int roomId,
  ) async {
    return Result.success(
      const LiveRoomDetail(
        roomId: 12345,
        title: 'Test Live Room',
        anchorName: 'Streamer',
        online: 100,
        isLive: true,
      ),
    );
  }

  @override
  Future<Result<MediaStream, Exception>> getLiveRoomStream(int roomId) async {
    return Result.error(Exception('Stream unavailable'));
  }
}

class _FakeLiveDataSourceWithStream extends LiveRoomDetailRemoteDataSource {
  _FakeLiveDataSourceWithStream(this._stream);

  final MediaStream _stream;

  @override
  String get sourceId => 'fake';

  @override
  Future<Result<LiveRoomDetail, Exception>> getLiveRoomDetail(
    int roomId,
  ) async {
    return Result.success(
      const LiveRoomDetail(
        roomId: 12345,
        title: 'Test Live Room',
        anchorName: 'Streamer',
        online: 100,
        isLive: true,
      ),
    );
  }

  @override
  Future<Result<MediaStream, Exception>> getLiveRoomStream(int roomId) async {
    return Result.success(_stream);
  }
}

void main() {
  testWidgets('LiveScreen displays stream error and retry button', (
    tester,
  ) async {
    final fakePlatform = _FakePlatformPlayer();
    final controller = MediaPlaybackController(fakePlatform);
    addTearDown(controller.dispose);
    addTearDown(fakePlatform.disposeStreams);

    final repo = AppLiveRoomRepository(_FakeLiveDataSource());

    await tester.pumpWidget(
      Provider<AppLiveRoomRepository>.value(
        value: repo,
        child: MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: LiveScreen(roomId: '12345', playbackController: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Failed to load live stream'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('LiveScreen danmaku settings button has localized tooltip', (
    tester,
  ) async {
    final fakePlatform = _FakePlatformPlayer();
    final controller = MediaPlaybackController(fakePlatform);
    addTearDown(controller.dispose);
    addTearDown(fakePlatform.disposeStreams);

    final mediaStream = MediaStream(
      url: 'https://example.com/live.m3u8',
      format: StreamFormat.hls,
    );
    final repo = AppLiveRoomRepository(
      _FakeLiveDataSourceWithStream(mediaStream),
    );

    await tester.pumpWidget(
      Provider<AppLiveRoomRepository>.value(
        value: repo,
        child: MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: LiveScreen(roomId: '12345', playbackController: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Toggle fullscreen to show overlay controls.
    final toggleFullscreenFinder = find.byTooltip('Fullscreen');
    if (toggleFullscreenFinder.evaluate().isNotEmpty) {
      await tester.tap(toggleFullscreenFinder);
      await tester.pumpAndSettle();
    }

    final l10n = AppLocalizations.of(tester.element(find.byType(LiveScreen)))!;
    final danmakuSettingsButton = find.byWidgetPredicate(
      (widget) =>
          widget is IconButton &&
          widget.tooltip == l10n.danmakuSettingsTitle &&
          widget.icon is Icon &&
          (widget.icon as Icon).icon == Icons.forum_outlined,
    );
    expect(danmakuSettingsButton, findsOneWidget);
  });
}

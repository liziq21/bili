import 'dart:async';

import 'package:app/data/repository/app_live_room_repository.dart';
import 'package:app/feature/live/live_screen.dart';
import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:app/l10n/localization_file/app_localizations.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:model/model.dart';
import 'package:provider/provider.dart';

/// 更完整的假播放器，参考 media_playback_controller_test.dart 的实现。
///
/// 提供足够的流防止 media_kit 在测试环境下触发原生代码路径导致 segfault。
class _FakePlatformPlayer() extends Fake implements PlatformPlayer {
  this {
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
  bool isVideoControllerAttached = false;

  @override
  late PlayerState state = PlayerState();

  @override
  Completer<VideoController> videoControllerCompleter =
      Completer<VideoController>();

  @override
  Future<int> get handle async => 0;

  @override
  late PlayerStream stream;

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
    _completed.close();
    _position.close();
    _duration.close();
    _volume.close();
    _rate.close();
    _pitch.close();
    _buffering.close();
    _buffer.close();
    _bufferingPercentage.close();
    _playlistMode.close();
    _shuffle.close();
    _audioParams.close();
    _videoParams.close();
    _audioBitrate.close();
    _audioDevice.close();
    _audioDevices.close();
    _track.close();
    _tracks.close();
    _width.close();
    _height.close();
    _subtitle.close();
    _log.close();
    _error.close();
    _playlist.close();
  }
}

class _FakeLiveDataSource() extends LiveRoomDetailRemoteDataSource {
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
}

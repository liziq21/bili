import 'dart:async';

import 'package:app/data/repository/video_detail_repository.dart';
import 'package:app/feature/video/bloc/video_bloc.dart';
import 'package:app/feature/video/common_widgets/video_player.dart';
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

  testWidgets('renders the stream error inside the player area', (
    WidgetTester tester,
  ) async {
    final bloc = VideoBloc(repository: _FailingStreamRepository());

    await pumpPlayer(tester, bloc: bloc);
    bloc.add(const LoadMediaStream('BV123'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.textContaining('播放失败'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

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

        expect(find.byTooltip('下一首'), findsOneWidget);
        expect(find.byTooltip('上一首'), findsOneWidget);

        await controller.openQueue([
          MediaStream(videoUrl: 'https://example.com/1.m4s'),
          MediaStream(videoUrl: 'https://example.com/2.m4s'),
        ]);
        await tester.pump();

        await tester.tap(find.byTooltip('下一首'));
        await tester.pump();
        expect(fake.nextCalls, hasLength(1));
        expect(fake.previousCalls, isEmpty);

        await tester.tap(find.byTooltip('上一首'));
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

      expect(find.byTooltip('循环：关闭'), findsOneWidget);

      await tester.tap(find.byTooltip('循环：关闭'));
      await tester.pump();
      expect(find.byTooltip('单首循环'), findsOneWidget);

      await tester.tap(find.byTooltip('单首循环'));
      await tester.pump();
      expect(find.byTooltip('队列循环'), findsOneWidget);

      await tester.tap(find.byTooltip('队列循环'));
      await tester.pump();
      expect(find.byTooltip('循环：关闭'), findsOneWidget);

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
}

class _NoStreamRepository() implements VideoDetailRepository {
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
  }) async {
    return Completer<Result<MediaStream>>().future;
  }
}

// ignore_for_file: close_sinks
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
  late PlayerState state;

  @override
  late PlayerStream stream;

  /// [PlatformPlayer.isVideoControllerAttached] — `VideoController`
  /// constructor writes this; [dispose] reads it.
  @override
  bool isVideoControllerAttached = false;

  final List<int> nextCalls = [];
  final List<int> previousCalls = [];
  final List<Playable> openCalls = [];
  final List<Duration> seekCalls = [];

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
  Future<void> dispose() async {}

  void injectPlaybackError(String message) => _error.add(message);
}

class _HangingStreamRepository() implements VideoDetailRepository {
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
  }) async {
    return Completer<Result<MediaStream>>().future;
  }
}

class _FailingStreamRepository() implements VideoDetailRepository {
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
  }) async => Result.error(Exception('签名过期'));
}

class _OkStreamRepository() implements VideoDetailRepository {
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
  }) async => Result.ok(MediaStream(videoUrl: 'https://example.com/v.m4s'));
}

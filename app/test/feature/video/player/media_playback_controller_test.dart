import 'dart:async';

import 'package:app/feature/video/player/media_playback_controller.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';

/// 只实现被观察的那几个流的假播放器。
///
/// 播放器库以「事件流」而非轮询状态的方式通知变化，故测试要复现真实的
/// 事件序列——包括某些状态变化**不会**再次发事件这一点。
// ignore_for_file: close_sinks

class _FakePlatformPlayer() extends Fake implements PlatformPlayer {
  this {
    // 位置参数顺序取自 PlayerStream 构造器签名，未被观察的流给空流。
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

  /// 记录收到的音量，换算前的原值。
  final List<double> volumeCalls = [];

  /// 记录收到的媒体地址。
  final List<String> openedUris = [];

  /// 记录收到的请求头。
  final List<Map<String, String>> openedHeaders = [];

  /// 投喂播放开关变化。
  void emitPlaying(bool value) => _playing.add(value);

  /// 投喂缓冲开关变化。
  void emitBuffering(bool value) => _buffering.add(value);

  /// 投喂播放位置变化。
  void emitPosition(Duration value) => _position.add(value);

  /// 投喂媒体时长变化。
  void emitDuration(Duration value) => _duration.add(value);

  /// 投喂播放错误。
  void emitError(String value) => _error.add(value);

  /// 投喂队列变化。
  void emitPlaylist(Playlist value) => _playlist.add(value);

  /// 投喂队列模式变化。
  void emitPlaylistMode(PlaylistMode value) => _playlistMode.add(value);

  /// 记录收到的队列。
  final List<Playlist> openedPlaylists = [];

  /// 记录收到的跳转、追加、移除、移动、模式设置调用。
  final List<int> nextCalls = [];
  final List<int> previousCalls = [];
  final List<int> jumpCalls = [];
  final List<Media> addedMedias = [];
  final List<int> removedIndexes = [];
  final List<({int from, int to})> movedItems = [];
  final List<PlaylistMode> setPlaylistModeCalls = [];

  @override
  Future<void> open(
    Playable playable, {
    bool play = true,
    bool synchronized = true,
  }) async {
    if (playable is Media) {
      openedUris.add(playable.uri);
      openedHeaders.add(playable.httpHeaders ?? const {});
    } else if (playable is Playlist) {
      openedPlaylists.add(playable);
      for (final media in playable.medias) {
        openedUris.add(media.uri);
        openedHeaders.add(media.httpHeaders ?? const {});
      }
    }
  }

  @override
  Future<void> setVolume(double volume, {bool synchronized = true}) async {
    volumeCalls.add(volume);
  }

  @override
  Future<void> next() async => nextCalls.add(0);

  @override
  Future<void> previous() async => previousCalls.add(0);

  @override
  Future<void> jump(int index) async => jumpCalls.add(index);

  @override
  Future<void> add(Media media) async => addedMedias.add(media);

  @override
  Future<void> remove(int index) async => removedIndexes.add(index);

  @override
  Future<void> move(int from, int to) async =>
      movedItems.add((from: from, to: to));

  @override
  Future<void> setPlaylistMode(PlaylistMode mode) async =>
      setPlaylistModeCalls.add(mode);

  @override
  Future<void> dispose() async {
    for (final controller in <StreamController<dynamic>>[
      _playlist,
      _playing,
      _completed,
      _position,
      _duration,
      _volume,
      _rate,
      _pitch,
      _buffering,
      _buffer,
      _bufferingPercentage,
      _playlistMode,
      _shuffle,
      _audioParams,
      _videoParams,
      _audioBitrate,
      _audioDevice,
      _audioDevices,
      _track,
      _tracks,
      _width,
      _height,
      _subtitle,
      _log,
      _error,
    ]) {
      await controller.close();
    }
  }
}

/// 收集状态流，供断言用。
class _Recorder() {
  final List<PlaybackState> states = [];
  late final StreamSubscription<PlaybackState> _subscription;

  void attach(Stream<PlaybackState> stream) {
    _subscription = stream.listen(states.add);
  }

  PlaybackState get last => states.last;

  Future<void> close() => _subscription.cancel();
}

void main() {
  late _FakePlatformPlayer fake;
  late MediaPlaybackController controller;
  late _Recorder recorder;

  setUp(() {
    fake = _FakePlatformPlayer();
    controller = MediaPlaybackController(fake);
    recorder = _Recorder()..attach(controller.states);
  });

  tearDown(() async {
    await recorder.close();
    await controller.dispose();
  });

  group('MediaPlaybackController.open', () {
    test(
      'passes the EDL address and the request headers to the player',
      () async {
        await controller.open(
          MediaStream(
            videoUrl: 'https://cdn.example.com/v.m4s',
            audioUrl: 'https://cdn.example.com/a.m4s',
            headers: {'Referer': 'https://www.bilibili.com'},
          ),
        );

        expect(fake.openedUris, hasLength(1));
        expect(fake.openedUris.single, startsWith('edl://'));
        expect(fake.openedUris.single, isNot(contains('\n')));
        expect(
          fake.openedHeaders.single['Referer'],
          'https://www.bilibili.com',
        );
      },
    );

    test('the state after opening is reset, not carried over from the previous media', () async {
      await controller.open(
        MediaStream(videoUrl: 'https://cdn.example.com/1.m4s'),
      );
      fake.emitPosition(const Duration(seconds: 30));
      fake.emitDuration(const Duration(minutes: 5));
      fake.emitPlaying(true);
      await pumpEventQueue();

      await controller.open(
        MediaStream(videoUrl: 'https://cdn.example.com/2.m4s'),
      );
      await pumpEventQueue();

      expect(recorder.last.position, Duration.zero);
      expect(recorder.last.duration, Duration.zero);
      expect(recorder.last.isPlaying, isFalse);
    });

    test('opening again clears the error of the previous media', () async {
      await controller.open(
        MediaStream(videoUrl: 'https://cdn.example.com/1.m4s'),
      );
      fake.emitError('403 forbidden');
      await pumpEventQueue();
      expect(recorder.last.error, '403 forbidden');

      await controller.open(
        MediaStream(videoUrl: 'https://cdn.example.com/2.m4s'),
      );
      await pumpEventQueue();

      expect(recorder.last.error, isNull);
    });
  });

  group('MediaPlaybackController reported playing state', () {
    // 播放器的播放开关在整个缓冲期间不变，因此缓冲结束时其播放状态流
    // 不会再发一次事件。只在缓冲事件里把播放状态置 false，会让状态永久
    // 卡在「未播放」。
    test(
      'recovers to playing when buffering ends without a new playing event',
      () async {
        await controller.open(
          MediaStream(videoUrl: 'https://cdn.example.com/v.m4s'),
        );

        fake.emitPlaying(true);
        await pumpEventQueue();
        expect(recorder.last.isPlaying, isTrue);

        fake.emitBuffering(true);
        await pumpEventQueue();
        expect(recorder.last.isPlaying, isFalse);
        expect(recorder.last.isBuffering, isTrue);

        // 缓冲结束，但播放开关未变，故这里没有新的 playing 事件。
        fake.emitBuffering(false);
        await pumpEventQueue();
        expect(recorder.last.isBuffering, isFalse);
        expect(recorder.last.isPlaying, isTrue);
      },
    );

    test(
      'is not playing while buffering even if the playing switch stays on',
      () async {
        await controller.open(
          MediaStream(videoUrl: 'https://cdn.example.com/v.m4s'),
        );

        fake.emitPlaying(true);
        fake.emitBuffering(true);
        await pumpEventQueue();

        expect(recorder.last.isPlaying, isFalse);
        expect(recorder.last.isBuffering, isTrue);
      },
    );

    test('is not playing when the player is paused', () async {
      await controller.open(
        MediaStream(videoUrl: 'https://cdn.example.com/v.m4s'),
      );

      fake.emitPlaying(true);
      await pumpEventQueue();
      fake.emitPlaying(false);
      await pumpEventQueue();

      expect(recorder.last.isPlaying, isFalse);
    });
  });

  group('MediaPlaybackController error retention', () {
    // 错误是异步抛出的，位置与时长更新仍会持续到达。错误若被这些更新
    // 冲掉，消费者可能永远看不到。
    test('a position update does not erase the error', () async {
      await controller.open(
        MediaStream(videoUrl: 'https://cdn.example.com/v.m4s'),
      );
      fake.emitError('EDL parsing failed');
      await pumpEventQueue();

      fake.emitPosition(const Duration(seconds: 5));
      await pumpEventQueue();

      expect(recorder.last.error, 'EDL parsing failed');
    });

    test('a duration and a buffering update do not erase the error', () async {
      await controller.open(
        MediaStream(videoUrl: 'https://cdn.example.com/v.m4s'),
      );
      fake.emitError('403 forbidden');
      await pumpEventQueue();

      fake.emitDuration(const Duration(minutes: 3));
      fake.emitBuffering(true);
      await pumpEventQueue();

      expect(recorder.last.error, '403 forbidden');
    });
  });

  group('MediaPlaybackController.setVolume', () {
    // 播放器库的量程是 0–100，本类对外声明 0–1。
    test('converts the 0-1 input to the 0-100 scale of the player', () async {
      await controller.setVolume(1);
      await controller.setVolume(0.5);
      await controller.setVolume(0);

      expect(fake.volumeCalls, [100.0, 50.0, 0.0]);
    });
  });

  group('MediaPlaybackController.openQueue', () {
    test(
      'builds an EDL media per queue item and keeps the given order',
      () async {
        await controller.openQueue([
          MediaStream(
            videoUrl: 'https://cdn.example.com/1v.m4s',
            audioUrl: 'https://cdn.example.com/1a.m4s',
            headers: {'Referer': 'https://www.bilibili.com'},
          ),
          MediaStream(videoUrl: 'https://cdn.example.com/2.m4s'),
        ]);

        expect(fake.openedPlaylists, hasLength(1));
        expect(fake.openedPlaylists.single.medias, hasLength(2));
        expect(fake.openedPlaylists.single.index, 0);
        // 每条队列项各自拼成 EDL，互不串扰。
        for (final uri in fake.openedUris) {
          expect(uri, startsWith('edl://'));
          expect(uri, isNot(contains('\n')));
        }
        // 队列项的请求头随各自媒体下发，不共用。
        expect(fake.openedHeaders[0]['Referer'], 'https://www.bilibili.com');
        expect(fake.openedHeaders[1], isEmpty);
      },
    );

    test('passes the requested starting index to the player', () async {
      await controller.openQueue([
        MediaStream(videoUrl: 'https://cdn.example.com/1.m4s'),
        MediaStream(videoUrl: 'https://cdn.example.com/2.m4s'),
      ], index: 1);

      expect(fake.openedPlaylists.single.index, 1);
    });

    test(
      'playlist updates surface as queue length and current index',
      () async {
        await controller.openQueue([
          MediaStream(videoUrl: 'https://cdn.example.com/1.m4s'),
          MediaStream(videoUrl: 'https://cdn.example.com/2.m4s'),
        ]);
        fake.emitPlaylist(
          Playlist([
            Media('https://cdn.example.com/1.m4s'),
            Media('https://cdn.example.com/2.m4s'),
          ], index: 0),
        );
        await pumpEventQueue();
        expect(recorder.last.queueLength, 2);
        expect(recorder.last.currentIndex, 0);

        // 播放器把指针挪到第三条：长度与序号都从 playlist 流流出。
        fake.emitPlaylist(
          Playlist([
            Media('https://cdn.example.com/1.m4s'),
            Media('https://cdn.example.com/2.m4s'),
            Media('https://cdn.example.com/3.m4s'),
          ], index: 2),
        );
        await pumpEventQueue();

        expect(recorder.last.queueLength, 3);
        expect(recorder.last.currentIndex, 2);
      },
    );
  });

  group('MediaPlaybackController queue edits', () {
    test('addToQueue forwards an EDL media with its own headers', () async {
      await controller.addToQueue(
        MediaStream(
          videoUrl: 'https://cdn.example.com/v.m4s',
          headers: {'Referer': 'https://www.bilibili.com'},
        ),
      );

      expect(fake.addedMedias, hasLength(1));
      expect(fake.addedMedias.single.uri, startsWith('edl://'));
      expect(
        fake.addedMedias.single.httpHeaders?['Referer'],
        'https://www.bilibili.com',
      );
    });

    test(
      'removeFromQueue, moveQueueItem and jumps forward the indexes',
      () async {
        await controller.removeFromQueue(2);
        await controller.moveQueueItem(0, 1);
        await controller.jumpTo(3);
        await controller.next();
        await controller.previous();

        expect(fake.removedIndexes, [2]);
        expect(fake.movedItems, [(from: 0, to: 1)]);
        expect(fake.jumpCalls, [3]);
        expect(fake.nextCalls, hasLength(1));
        expect(fake.previousCalls, hasLength(1));
      },
    );
  });

  group('MediaPlaybackController.setQueueMode', () {
    test('maps the public enum onto the library playlist mode', () async {
      await controller.setQueueMode(PlaybackQueueMode.single);
      await controller.setQueueMode(PlaybackQueueMode.loop);
      await controller.setQueueMode(PlaybackQueueMode.none);

      expect(fake.setPlaylistModeCalls, [
        PlaylistMode.single,
        PlaylistMode.loop,
        PlaylistMode.none,
      ]);
    });

    test('playlist mode updates surface as the public enum', () async {
      await controller.openQueue([
        MediaStream(videoUrl: 'https://cdn.example.com/1.m4s'),
      ]);
      fake.emitPlaylistMode(PlaylistMode.loop);
      await pumpEventQueue();
      expect(recorder.last.queueMode, PlaybackQueueMode.loop);

      fake.emitPlaylistMode(PlaylistMode.single);
      await pumpEventQueue();
      expect(recorder.last.queueMode, PlaybackQueueMode.single);
    });
  });
}

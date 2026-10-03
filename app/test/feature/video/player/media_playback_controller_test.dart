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
    state = PlayerState();
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

  @override
  Future<void> open(
    Playable playable, {
    bool play = true,
    bool synchronized = true,
  }) async {
    if (playable is Media) {
      openedUris.add(playable.uri);
      openedHeaders.add(playable.httpHeaders ?? const {});
    }
  }

  @override
  Future<void> setVolume(double volume, {bool synchronized = true}) async {
    volumeCalls.add(volume);
  }

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
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';

/// A [PlatformPlayer] that answers without libmpv.
///
/// [MediaPlaybackController] only needs a [PlayerStream] to subscribe to and a
/// few commands it can await; the real player needs `MediaKit.ensureInitialized`
/// and a platform texture, neither of which exists under `flutter test`.
///
/// The call lists are what assertions read: [openCalls] and [seekCalls] are how
/// a test tells "played from the start" from "resumed at the saved second".
///
/// Declared here rather than inside one test file because both the player
/// widget tests and the page-level resume test drive the same controller.
// ignore_for_file: close_sinks
class FakePlatformPlayer() extends Fake implements PlatformPlayer {
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

  /// 固定的原生句柄：[NativeVideoController.create] 用它做缓存键与纹理注册。
  @override
  final Future<int> handle = Future.value(42);

  /// [NativeVideoController.create] 注册 [Player.dispose] 回调到这里。
  @override
  final List<Future<void> Function()> release = [];

  final List<int> nextCalls = [];
  final List<int> previousCalls = [];
  final List<Playable> openCalls = [];
  final List<Duration> seekCalls = [];
  final List<double> rateCalls = [];

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
    // 模拟 real.dart stop(open:true, notify:true) 的 reset 事件序列：
    // playing=false、completed=false、position/duration/buffer=zero、buffering=false。
    _playing.add(false);
    _completed.add(false);
    _position.add(Duration.zero);
    _duration.add(Duration.zero);
    _buffering.add(false);
    _buffer.add(Duration.zero);
    if (play) {
      _playing.add(true);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    seekCalls.add(position);
  }

  @override
  Future<void> setRate(double rate) async {
    rateCalls.add(rate);
    _rate.add(rate);
  }

  /// 投喂一次速率事件，驱动 [MediaPlaybackController.states] 的 rate 字段。
  void emitRate(double rate) => _rate.add(rate);

  @override
  Future<void> dispose() async {}

  void injectPlaybackError(String message) => _error.add(message);
}

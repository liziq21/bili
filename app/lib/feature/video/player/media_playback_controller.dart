import 'dart:async';

import 'package:data/data.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'media_edl.dart';

/// 播放层的对外状态。
///
/// 播放层不暴露 media_kit 的类型：具体播放器库的 API 变化不应该波及
/// 业务代码，UI 只消费本状态。
class PlaybackState({
  /// 是否正在播放。缓冲中为 false——此时进度并未推进，进度条不该继续走。
  required final bool isPlaying,

  /// 是否处于缓冲。
  required final bool isBuffering,

  /// 当前播放位置。
  required final Duration position,

  /// 媒体总时长，源未提供时为零。
  required final Duration duration,

  /// 播放错误信息，无错误时为 null。
  ///
  /// 播放器库以流的形式异步抛出错误，加载完成后才能拿到，因此打开成功
  /// 不代表一定能播下去。错误一经产生就保持到下次 [MediaPlaybackController.open]，
  /// 不被后续位置、时长等状态更新冲掉。
  final String? error,

  /// 队列长度。未打开队列时为 0。
  final int queueLength = 0,

  /// 队列里正在播放的序号，没有队列时为 0。
  final int currentIndex = 0,

  /// 队列播放模式，无队列时为 [PlaybackQueueMode.none]。
  final PlaybackQueueMode queueMode = PlaybackQueueMode.none,
});

/// 队列播放模式，语义对齐播放器库的 [PlaylistMode]。
enum PlaybackQueueMode() {
  /// 播完队列即停。
  none,

  /// 单条循环。
  single,

  /// 整队列循环。
  loop,
}

extension on PlaybackState {
  /// 复制本状态，未显式给出的字段沿用原值。
  PlaybackState copyWith({
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    String? error,
    int? queueLength,
    int? currentIndex,
    PlaybackQueueMode? queueMode,
  }) {
    return PlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: error ?? this.error,
      queueLength: queueLength ?? this.queueLength,
      currentIndex: currentIndex ?? this.currentIndex,
      queueMode: queueMode ?? this.queueMode,
    );
  }
}

/// 会话初始状态：未播放、未缓冲、位置与时长归零、无错误。
///
/// 换媒体时用：上一条媒体的错误、位置、时长都不该带进新会话。
PlaybackState _initialPlaybackState() => PlaybackState(
  isPlaying: false,
  isBuffering: false,
  position: Duration.zero,
  duration: Duration.zero,
);

/// 一条可播放媒体的会话。
///
/// 负责把 [MediaStream] 变成播放器能打开的地址并驱动播放。各服务的
/// 音视频分离与分段形态由 [MediaEdl] 收敛为单个虚拟媒体地址，本类不再
/// 关心源侧差异。
///
/// 本类持有原生播放器资源，调用方必须在生命周期结束时 [dispose]。
class MediaPlaybackController([
  // 声明式参数不能引用私有字段（`initializing_formal_for_non_existent_field`），
  // 故此处用位置参数 + 字段声明，并压掉随之而来的建议。
  // ignore: use_declaring_parameters
  PlatformPlayer? platformPlayer,
]) {
  /// 测试注入的播放器实现，为 null 时用真实的原生播放器。
  final PlatformPlayer? _platformPlayer = platformPlayer;

  /// 惰性建 Player：原生库须先初始化，故由 [_createPlayer] 承担。
  late final Player _player = _createPlayer(_platformPlayer);

  /// [_player] 是否已被访问过（late final 首次取值即初始化）。
  /// dispose 只在原生播放器确实创建过才释放，避免无头测试里
  /// 访问未初始化的 late 字段触发 [MediaKit.ensureInitialized]。
  bool _playerTouched = false;

  /// 在首次使用 [_player] 时标记，供 [dispose] 判断是否需要释放。
  Player get _touchedPlayer {
    _playerTouched = true;
    return _player;
  }

  late final VideoController _videoController = VideoController(_player);

  final StreamController<PlaybackState> _stateController =
      StreamController<PlaybackState>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  PlaybackState _state = _initialPlaybackState();

  /// 播放器的播放与缓冲开关各自的状态。
  ///
  /// 两者分开存而非只存派生结果：缓冲结束时播放器的播放开关并未变化，
  /// 其播放状态流不会再发一次事件，只存派生结果会永久卡在「未播放」。
  bool _isPlaying = false;
  bool _isBuffering = false;

  static Player _createPlayer(PlatformPlayer? platformPlayer) {
    if (platformPlayer != null) return Player(platformPlayer: platformPlayer);
    MediaKit.ensureInitialized();
    return Player();
  }

  /// 视频渲染控制器，交给 `Video` 组件使用。
  VideoController get videoController => _videoController;

  /// 状态流。加载与播放过程中的变化都从这里流出。
  ///
  /// 订阅本身不触发原生库初始化：未 [open] 过时不产出任何状态。
  Stream<PlaybackState> get states => _stateController.stream;

  /// 当前状态快照。
  PlaybackState get state => _state;

  /// 打开一条媒体并开始播放。
  ///
  /// [stream] 携带的地址可能已失效（各服务的地址签名都有时效），此时
  /// 错误经 [states] 的 [PlaybackState.error] 报出。重复打开会先把状态
  /// 归零，避免上一条媒体的位置与时长被当成本条媒体的。
  Future<void> open(MediaStream stream) async {
    _subscribe();
    _isPlaying = false;
    _isBuffering = false;
    _emit(_initialPlaybackState());
    await _player.open(
      Media(MediaEdl.uriOf(stream), httpHeaders: stream.headers),
    );
  }

  /// 暂停。
  Future<void> pause() => _player.pause();

  /// 继续播放。
  Future<void> play() => _player.play();

  /// 播放与暂停互切。
  Future<void> playOrPause() => _player.playOrPause();

  /// 跳转到指定位置。
  Future<void> seek(Duration position) => _player.seek(position);

  /// 设置音量，取值 0 到 1。
  ///
  /// 播放器库的量程是 0 到 100，此处对外用 0 到 1 并在转发前换算。
  Future<void> setVolume(double volume) => _player.setVolume(volume * 100);

  /// 打开一个播放队列并从头（或指定序号）开始播放。
  ///
  /// 每条 [MediaStream] 各自拼成 EDL 虚拟媒体，互不干扰。队列为空时
  /// 交给播放器库的空 [Playlist] 不会播放任何内容。
  Future<void> openQueue(List<MediaStream> streams, {int index = 0}) async {
    _subscribe();
    _isPlaying = false;
    _isBuffering = false;
    _emit(_initialPlaybackState());
    await _player.open(
      Playlist(
        streams
            .map(
              (stream) =>
                  Media(MediaEdl.uriOf(stream), httpHeaders: stream.headers),
            )
            .toList(),
        index: index,
      ),
    );
  }

  /// 追加一条媒体到队列末尾。
  Future<void> addToQueue(MediaStream stream) =>
      _player.add(Media(MediaEdl.uriOf(stream), httpHeaders: stream.headers));

  /// 移除队列中指定序号的条目。
  Future<void> removeFromQueue(int index) => _player.remove(index);

  /// 移动队列条目：把 [from] 挪到 [to] 的位置。
  Future<void> moveQueueItem(int from, int to) => _player.move(from, to);

  /// 跳到队列的下一首。
  Future<void> next() => _player.next();

  /// 跳到队列的上一首。
  Future<void> previous() => _player.previous();

  /// 跳到队列中指定序号的条目。
  Future<void> jumpTo(int index) => _player.jump(index);

  /// 设置队列播放模式。
  Future<void> setQueueMode(PlaybackQueueMode mode) =>
      _player.setPlaylistMode(_playlistModeOf(mode));

  /// 队列播放模式 → 播放器库枚举。
  PlaylistMode _playlistModeOf(PlaybackQueueMode mode) {
    switch (mode) {
      case PlaybackQueueMode.none:
        return PlaylistMode.none;
      case PlaybackQueueMode.single:
        return PlaylistMode.single;
      case PlaybackQueueMode.loop:
        return PlaylistMode.loop;
    }
  }

  /// 播放器库枚举 → 队列播放模式。
  PlaybackQueueMode _queueModeOf(PlaylistMode mode) {
    switch (mode) {
      case PlaylistMode.none:
        return PlaybackQueueMode.none;
      case PlaylistMode.single:
        return PlaybackQueueMode.single;
      case PlaylistMode.loop:
        return PlaybackQueueMode.loop;
    }
  }

  /// 释放原生播放器资源。
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _stateController.close();
    if (_playerTouched) await _player.dispose();
  }

  /// 订阅播放器状态。重复调用只生效一次。
  ///
  /// 订阅延迟到首次 [open]：未装载媒体时收位置与时长没有意义。
  void _subscribe() {
    if (_subscriptions.isNotEmpty) return;
    _subscriptions.addAll([
      _player.stream.playing.listen((playing) {
        _isPlaying = playing;
        _emit(_state.copyWith(isPlaying: _reportedPlaying));
      }),
      _player.stream.buffering.listen((buffering) {
        _isBuffering = buffering;
        _emit(
          _state.copyWith(isBuffering: buffering, isPlaying: _reportedPlaying),
        );
      }),
      _player.stream.position.listen((position) {
        _emit(_state.copyWith(position: position));
      }),
      _player.stream.duration.listen((duration) {
        _emit(_state.copyWith(duration: duration));
      }),
      _player.stream.error.listen((error) {
        _emit(_state.copyWith(error: error));
      }),
      _player.stream.playlist.listen((playlist) {
        _emit(
          _state.copyWith(
            queueLength: playlist.medias.length,
            currentIndex: playlist.index,
          ),
        );
      }),
      _player.stream.playlistMode.listen((mode) {
        _emit(_state.copyWith(queueMode: _queueModeOf(mode)));
      }),
    ]);
  }

  /// 对外报的播放状态：播放开关打开且不在缓冲才算在播。
  bool get _reportedPlaying => _isPlaying && !_isBuffering;

  void _emit(PlaybackState next) {
    _state = next;
    if (!_stateController.isClosed) _stateController.add(next);
  }
}

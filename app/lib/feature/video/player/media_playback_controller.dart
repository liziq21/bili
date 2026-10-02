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
  /// 是否正在播放。缓冲中按「非播放」报，避免进度条继续走。
  required final bool isPlaying,

  /// 是否处于缓冲。缓冲期间 [isPlaying] 为 false。
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
});

extension on PlaybackState {
  /// 复制本状态，未显式给出的字段沿用原值。
  PlaybackState copyWith({
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    String? error,
  }) {
    return PlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: error ?? this.error,
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
class MediaPlaybackController() {
  /// 惰性建 Player：原生库须先初始化，故由 [_createPlayer] 承担。
  late final Player _player = _createPlayer();

  late final VideoController _videoController = VideoController(_player);

  final StreamController<PlaybackState> _stateController =
      StreamController<PlaybackState>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  PlaybackState _state = _initialPlaybackState();

  static Player _createPlayer() {
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

  /// 释放原生播放器资源。
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _stateController.close();
    await _player.dispose();
  }

  /// 订阅播放器状态。重复调用只生效一次。
  ///
  /// 订阅延迟到首次 [open]：未装载媒体时收位置与时长没有意义。
  void _subscribe() {
    if (_subscriptions.isNotEmpty) return;
    _subscriptions.addAll([
      _player.stream.playing.listen((playing) {
        _emit(_state.copyWith(isPlaying: playing));
      }),
      _player.stream.buffering.listen((buffering) {
        // 缓冲期按未播放报：播放器此时并未推进，进度条不该继续走。
        _emit(_state.copyWith(isBuffering: buffering, isPlaying: false));
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
    ]);
  }

  void _emit(PlaybackState next) {
    _state = next;
    if (!_stateController.isClosed) _stateController.add(next);
  }
}

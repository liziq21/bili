import 'dart:async';

import 'package:data/data.dart';
import 'package:equatable/equatable.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:meta/meta.dart';

import 'media_edl.dart';
import 'playback_error.dart';

/// 播放层的对外状态。
///
/// 播放层不暴露 media_kit 的类型：具体播放器库的 API 变化不应该波及
/// 业务代码，UI 只消费本状态。
@immutable
class const PlaybackState({
  /// 是否正在播放。缓冲中为 false——此时进度并未推进，进度条不该继续走。
  required final bool isPlaying,

  /// 是否处于缓冲。
  required final bool isBuffering,

  /// 当前播放位置。
  required final Duration position,

  /// 媒体总时长，源未提供时为零。
  required final Duration duration,

  /// 播放错误，无错误时为 null。
  ///
  /// 播放器库以流的形式异步抛出错误，加载完成后才能拿到，因此打开成功
  /// 不代表一定能播下去。错误一经产生就保持到下次 [MediaPlaybackController.open]，
  /// 不被后续位置、时长等状态更新冲掉。
  final MediaPlaybackException? error,

  /// 是否正在等待或执行一次自动重试。
  final bool isRetrying = false,

  /// 当前自动重试序号，从 1 开始；未重试时为 0。
  final int retryAttempt = 0,

  /// 当前播放速率，1.0 为正常速度。
  final double rate = 1.0,

  /// 当前音量，0 到 1。
  final double volume = 1.0,

  /// 队列长度。未打开队列时为 0。
  final int queueLength = 0,

  /// 队列里正在播放的序号，没有队列时为 0。
  final int currentIndex = 0,

  /// 队列播放模式，无队列时为 [PlaybackQueueMode.none]。
  final PlaybackQueueMode queueMode = PlaybackQueueMode.none,
}) extends Equatable {
  @override
  List<Object?> get props => [
    isPlaying,
    isBuffering,
    position,
    duration,
    error,
    isRetrying,
    retryAttempt,
    rate,
    volume,
    queueLength,
    currentIndex,
    queueMode,
  ];
}

/// 队列播放模式，语义对齐播放器库的 [PlaylistMode]。
enum PlaybackQueueMode() {
  /// 播完队列即停。
  none,

  /// 单条循环。
  single,

  /// 整队列循环。
  loop,
}

/// Metadata shown for one item in the playback queue.
///
/// [MediaStream] deliberately contains only playback data. Keeping the
/// presentation metadata here lets the player remain source-neutral while the
/// queue can still show useful titles and thumbnails.
@immutable
class const PlaybackQueueItem({
  required final MediaStream stream,
  final String? videoId,
  final String? title,
  final String? creatorName,
  final String? thumbnailUrl,
}) extends Equatable {
  @override
  List<Object?> get props => [
    stream.videoUrl,
    stream.audioUrl,
    videoId,
    title,
    creatorName,
    thumbnailUrl,
  ];

  PlaybackQueueItem copyWith({
    String? videoId,
    String? title,
    String? creatorName,
    String? thumbnailUrl,
  }) {
    return PlaybackQueueItem(
      stream: stream,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      creatorName: creatorName ?? this.creatorName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
}

extension on PlaybackState {
  /// 复制本状态，未显式给出的字段沿用原值。
  PlaybackState copyWith({
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    MediaPlaybackException? error,
    bool clearError = false,
    bool? isRetrying,
    int? retryAttempt,
    double? rate,
    double? volume,
    int? queueLength,
    int? currentIndex,
    PlaybackQueueMode? queueMode,
  }) {
    return PlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: clearError ? null : (error ?? this.error),
      isRetrying: isRetrying ?? this.isRetrying,
      retryAttempt: retryAttempt ?? this.retryAttempt,
      rate: rate ?? this.rate,
      volume: volume ?? this.volume,
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
  PlaybackRetryPolicy retryPolicy = const PlaybackRetryPolicy(),
]) {
  /// 测试注入的播放器实现，为 null 时用真实的原生播放器。
  final PlatformPlayer? _platformPlayer = platformPlayer;

  /// 自动重试配置。网络错误才会使用该策略，其他错误保留给用户手动处理。
  final PlaybackRetryPolicy _retryPolicy = retryPolicy;

  /// 惰性建 Player：原生库须先初始化，故由 [_createPlayer] 承担。
  late final Player _player = _createPlayer(_platformPlayer);

  /// [_player] 是否已被访问过（late final 首次取值即初始化）。
  /// dispose 只在原生播放器确实创建过才释放，避免无头测试里
  /// 在首次使用 [_player] 时标记，供 [dispose] 判断是否需要释放。
  bool _playerTouched = false;

  late final VideoController _videoController = VideoController(_player);

  final StreamController<PlaybackState> _stateController =
      StreamController<PlaybackState>.broadcast();
  final StreamController<List<PlaybackQueueItem>> _queueItemController =
      StreamController<List<PlaybackQueueItem>>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  StreamSubscription<String>? _errorSubscription;
  bool _acceptPlayerErrors = false;

  Timer? _retryTimer;
  final List<MediaStream> _queueStreams = [];
  List<PlaybackQueueItem> _queueItems = const [];
  MediaStream? _currentStream;
  bool _queueModeActive = false;
  int _retryAttempt = 0;
  int _openGeneration = 0;

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

  /// 当前正在播放的媒体；队列切换时跟随播放器的当前序号更新。
  MediaStream? get currentStream => _currentStream;

  /// 队列条目的元数据快照。
  List<PlaybackQueueItem> get queueItems => _queueItems;

  /// 队列条目的变化流。订阅者应使用 [queueItems] 读取初始快照。
  Stream<List<PlaybackQueueItem>> get queueItemStates =>
      _queueItemController.stream;

  /// 暂停。
  Future<void> pause() => _player.pause();

  /// 继续播放。
  Future<void> play() => _player.play();

  /// 播放与暂停互切。
  Future<void> playOrPause() => _player.playOrPause();

  /// 跳转到指定位置。
  Future<void> seek(Duration position) => _player.seek(position);

  /// 重新打开指定 stream（用于播放错误后重试）。
  ///
  /// 用户手动重试会取消等待中的自动重试，并重新开始自动重试预算。
  Future<void> retry(MediaStream stream) async {
    _cancelAutomaticRetry();
    _retryAttempt = 0;
    _currentStream = stream;
    final generation = ++_openGeneration;
    await _openStream(stream, generation: generation, preserveQueue: true);
  }

  /// 设置音量，取值 0 到 1。
  ///
  /// 播放器库的量程是 0 到 100，此处对外用 0 到 1 并在转发前换算。
  Future<void> setVolume(double volume) => _player.setVolume(volume * 100);

  /// 设置播放速率，1.0 为正常速度。
  Future<void> setRate(double rate) => _player.setRate(rate);

  /// 打开一个播放队列并从头（或指定序号）开始播放。
  ///
  /// 每条 [MediaStream] 各自拼成 EDL 虚拟媒体，互不干扰。队列为空时
  /// 交给播放器库的空 [Playlist] 不会播放任何内容。
  Future<void> openQueue(List<MediaStream> streams, {int index = 0}) async {
    await openQueueItems(
      streams.map((stream) => PlaybackQueueItem(stream: stream)).toList(),
      index: index,
    );
  }

  /// 打开带展示元数据的播放队列。
  Future<void> openQueueItems(
    List<PlaybackQueueItem> items, {
    int index = 0,
  }) async {
    final streams = items.map((item) => item.stream).toList();
    unawaited(_detachErrorSubscription());
    _cancelAutomaticRetry();
    _queueStreams
      ..clear()
      ..addAll(streams);
    _setQueueItems(items);
    _queueModeActive = true;
    _currentStream = streams.isEmpty ? null : streams[index];
    _retryAttempt = 0;
    final generation = ++_openGeneration;
    _playerTouched = true;
    _subscribe();
    _isPlaying = false;
    _isBuffering = false;
    _emit(
      PlaybackState(
        isPlaying: false,
        isBuffering: false,
        position: Duration.zero,
        duration: Duration.zero,
        queueLength: streams.length,
        currentIndex: index,
      ),
    );
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
    if (generation == _openGeneration) _subscribeToPlayerErrors(generation);
  }

  /// 追加一条媒体到队列末尾。
  Future<void> addToQueue(
    MediaStream stream, {
    String? videoId,
    String? title,
    String? creatorName,
    String? thumbnailUrl,
  }) async {
    await _player.add(
      Media(MediaEdl.uriOf(stream), httpHeaders: stream.headers),
    );
    _queueStreams.add(stream);
    _setQueueItems([
      ..._queueItems,
      PlaybackQueueItem(
        stream: stream,
        videoId: videoId,
        title: title,
        creatorName: creatorName,
        thumbnailUrl: thumbnailUrl,
      ),
    ]);
  }

  /// 移除队列中指定序号的条目。
  Future<void> removeFromQueue(int index) async {
    await _player.remove(index);
    if (index >= 0 && index < _queueStreams.length) {
      _queueStreams.removeAt(index);
      final nextItems = [..._queueItems]..removeAt(index);
      _setQueueItems(nextItems);
    }
  }

  /// 移动队列条目：把 [from] 挪到 [to] 的位置。
  Future<void> moveQueueItem(int from, int to) async {
    await _player.move(from, to);
    if (from >= 0 &&
        from < _queueStreams.length &&
        to >= 0 &&
        to < _queueStreams.length &&
        from < _queueItems.length &&
        to < _queueItems.length) {
      final stream = _queueStreams.removeAt(from);
      _queueStreams.insert(to, stream);
      final nextItems = [..._queueItems];
      final item = nextItems.removeAt(from);
      nextItems.insert(to, item);
      _setQueueItems(nextItems);
    }
  }

  /// Fills in metadata after a queue item has been resolved from a video id.
  void updateQueueItemMetadata({
    required String videoId,
    String? title,
    String? creatorName,
    String? thumbnailUrl,
  }) {
    final index = _queueItems.lastIndexWhere((item) => item.videoId == videoId);
    if (index < 0) return;
    _updateQueueItem(
      index,
      title: title,
      creatorName: creatorName,
      thumbnailUrl: thumbnailUrl,
    );
  }

  /// Updates the item currently shown by the player.
  void updateCurrentQueueItemMetadata({
    String? videoId,
    String? title,
    String? creatorName,
    String? thumbnailUrl,
  }) {
    if (_queueItems.isEmpty) return;
    final index = _state.currentIndex.clamp(0, _queueItems.length - 1).toInt();
    _updateQueueItem(
      index,
      videoId: videoId,
      title: title,
      creatorName: creatorName,
      thumbnailUrl: thumbnailUrl,
    );
  }

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

  /// 恢复起播位置（秒），在 [open] 完成后自动 seek。
  ///
  /// 由调用方在 [open] 之前赋值，播放层在 `open` 成功后 seek 到此位置，
  /// 用于进度续播场景。
  int restorePositionSeconds = 0;

  /// 释放原生播放器资源。
  Future<void> dispose() async {
    await _detachErrorSubscription();
    _cancelAutomaticRetry();
    _currentStream = null;
    _queueModeActive = false;
    _openGeneration++;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _stateController.close();
    await _queueItemController.close();
    if (_playerTouched) await _player.dispose();
  }

  /// 打开一条媒体并开始播放。
  ///
  /// [stream] 携带的地址可能已失效（各服务的地址签名都有时效），此时
  /// 错误经 [states] 的 [PlaybackState.error] 报出。重复打开会先把状态
  /// 归零，避免上一条媒体的位置与时长被当成本条媒体的。
  Future<void> open(
    MediaStream stream, {
    String? videoId,
    String? title,
    String? creatorName,
    String? thumbnailUrl,
  }) async {
    _cancelAutomaticRetry();
    _retryAttempt = 0;
    _queueStreams
      ..clear()
      ..add(stream);
    _setQueueItems([
      PlaybackQueueItem(
        stream: stream,
        videoId: videoId,
        title: title,
        creatorName: creatorName,
        thumbnailUrl: thumbnailUrl,
      ),
    ]);
    _queueModeActive = false;
    _currentStream = stream;
    final generation = ++_openGeneration;
    await _openStream(stream, generation: generation);
  }

  Future<void> _openStream(
    MediaStream stream, {
    required int generation,
    bool automaticRetry = false,
    bool preserveQueue = false,
  }) async {
    // Stop accepting errors from the old media immediately, but do not make a
    // retry wait for the media-kit's subscription cancellation future before
    // clearing the visible error state.
    unawaited(_detachErrorSubscription());
    if (generation != _openGeneration) return;
    _playerTouched = true;
    _subscribe();
    _isPlaying = false;
    _isBuffering = false;
    final initialState = preserveQueue
        ? _state.copyWith(
            isPlaying: false,
            isBuffering: false,
            position: Duration.zero,
            duration: Duration.zero,
            clearError: !automaticRetry,
            isRetrying: automaticRetry,
            retryAttempt: _retryAttempt,
          )
        : _initialPlaybackState();
    _emit(initialState);
    try {
      final playable = preserveQueue && _queueModeActive
          ? Playlist(
              _queueStreams
                  .map(
                    (item) =>
                        Media(MediaEdl.uriOf(item), httpHeaders: item.headers),
                  )
                  .toList(),
              index: _state.currentIndex,
            )
          : Media(MediaEdl.uriOf(stream), httpHeaders: stream.headers);
      await _player.open(playable);
      if (generation != _openGeneration) return;
      _subscribeToPlayerErrors(generation);
      if (restorePositionSeconds > 0) {
        await _player.seek(Duration(seconds: restorePositionSeconds));
        restorePositionSeconds = 0;
      }
    } on Object catch (error) {
      if (generation != _openGeneration) return;
      _subscribeToPlayerErrors(generation);
      _handlePlayerError(error, generation: generation);
    }
  }

  /// 订阅播放器状态。重复调用只生效一次。
  ///
  /// 订阅延迟到首次 [open]：未装载媒体时收位置与时长没有意义。
  void _subscribe() {
    if (_subscriptions.isNotEmpty) return;
    _subscriptions.addAll([
      _player.stream.playing.listen((playing) {
        _isPlaying = playing;
        if (playing && _state.isRetrying) {
          _cancelAutomaticRetry();
          _retryAttempt = 0;
          _emit(
            _state.copyWith(
              clearError: true,
              isRetrying: false,
              retryAttempt: 0,
              isPlaying: _reportedPlaying,
            ),
          );
        } else {
          _emit(_state.copyWith(isPlaying: _reportedPlaying));
        }
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
      _player.stream.rate.listen((rate) {
        _emit(_state.copyWith(rate: rate));
      }),
      // 播放器库音量量程 0 到 100，对外换算成 0 到 1。
      _player.stream.volume.listen((volume) {
        _emit(_state.copyWith(volume: (volume / 100).clamp(0.0, 1.0)));
      }),
      _player.stream.duration.listen((duration) {
        _emit(_state.copyWith(duration: duration));
      }),
      _player.stream.playlist.listen((playlist) {
        if (_queueModeActive && playlist.index != _state.currentIndex) {
          _cancelAutomaticRetry();
          _retryAttempt = 0;
          _openGeneration++;
          _currentStream = playlist.index < _queueStreams.length
              ? _queueStreams[playlist.index]
              : null;
        }
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

  void _subscribeToPlayerErrors(int generation) {
    _errorSubscription?.cancel();
    _acceptPlayerErrors = true;
    _errorSubscription = _player.stream.error.listen(
      (error) => _handlePlayerError(error, generation: generation),
    );
  }

  Future<void> _detachErrorSubscription() async {
    _acceptPlayerErrors = false;
    final subscription = _errorSubscription;
    _errorSubscription = null;
    await subscription?.cancel();
  }

  void _handlePlayerError(Object error, {int? generation}) {
    if (!_acceptPlayerErrors) return;
    if (generation != null && generation != _openGeneration) return;

    final playbackError = error is MediaPlaybackException
        ? error
        : MediaPlaybackException.fromMessage(error.toString());
    final stream = _currentStream;
    final canRetry =
        stream != null &&
        _retryPolicy.shouldAutomaticallyRetry(playbackError) &&
        _retryAttempt < _retryPolicy.maxRetries;

    if (!canRetry) {
      _emit(_state.copyWith(error: playbackError, isRetrying: false));
      return;
    }

    _retryTimer?.cancel();
    final retryAttempt = ++_retryAttempt;
    final scheduledGeneration = _openGeneration;
    final delay = _retryPolicy.delayForRetry(retryAttempt);
    _emit(
      _state.copyWith(
        error: playbackError,
        isRetrying: true,
        retryAttempt: retryAttempt,
      ),
    );
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      if (scheduledGeneration != _openGeneration || stream != _currentStream) {
        return;
      }
      final retryGeneration = ++_openGeneration;
      unawaited(
        _openStream(
          stream,
          generation: retryGeneration,
          automaticRetry: true,
          preserveQueue: true,
        ),
      );
    });
  }

  void _cancelAutomaticRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// 对外报的播放状态：播放开关打开且不在缓冲才算在播。
  bool get _reportedPlaying => _isPlaying && !_isBuffering;

  void _emit(PlaybackState next) {
    _state = next;
    if (!_stateController.isClosed) _stateController.add(next);
  }

  void _updateQueueItem(
    int index, {
    String? videoId,
    String? title,
    String? creatorName,
    String? thumbnailUrl,
  }) {
    if (index < 0 || index >= _queueItems.length) return;
    final nextItems = [..._queueItems];
    nextItems[index] = nextItems[index].copyWith(
      videoId: videoId,
      title: title,
      creatorName: creatorName,
      thumbnailUrl: thumbnailUrl,
    );
    _setQueueItems(nextItems);
  }

  void _setQueueItems(List<PlaybackQueueItem> items) {
    _queueItems = List.unmodifiable(items);
    if (!_queueItemController.isClosed) _queueItemController.add(_queueItems);
  }
}

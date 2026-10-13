import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:material_ui/material_ui.dart';
// media_kit_video 也导出名为 VideoState 的控件状态类，与本页 bloc 的
// VideoState 同名。此处藏掉它，VideoState 全指 bloc 的状态。
import 'package:media_kit_video/media_kit_video.dart' hide VideoState;
import 'package:model/model.dart';

import '../../../datastore/preferences_data_source.dart';
import '../../../data/repository/video_detail_repository.dart';
import 'playback_speed_chip.dart';
import 'player_gesture_layer.dart';
import 'quality_picker_chip.dart';
import 'sleep_timer_chip.dart';
import '../../../l10n/localization_file/app_localizations.dart';
import '../../../main.dart';
import '../bloc/video_bloc.dart';
import '../player/brightness_service.dart';
import '../player/media_playback_controller.dart';

/// 视频播放器：把 [MediaStream] 接到原生播放管线并渲染画面。
///
/// 替代 `VideoPlayerPlaceholder` 的假件。播放地址由 [VideoBloc] 在
/// [LoadMediaStream] 里解析，本组件只负责拿到就播、出错就显示在播放区域内——
/// 简介与评论区不受影响。
///
/// 队列层：画面下方的控制条提供下一首 / 上一首 / 循环播放模式，直接调用
/// [MediaPlaybackController] 的队列 API。控制条只在 [controller] 非 null
/// （即由 [VideoScreen] 页面级注入）时渲染；单独使用本组件（如既有 widget
/// 测试）时保持旧行为，不渲染控制条。
class const VideoPlayer({
  super.key,
  final double aspectRatio = 16 / 9,

  /// 播放器会话，为 null 时组件自建并在销毁时释放。
  ///
  /// 测试用它注入假实现：真实的 [MediaPlaybackController] 会初始化原生库，
  /// 在 widget 测试环境里起不来。
  final MediaPlaybackController? controller,
}) extends StatefulWidget {
  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState() extends State<VideoPlayer> {
  MediaPlaybackController? _playback;

  /// 是否由本组件创建（进而由本组件释放），区别于外部注入的会话。
  bool _ownsPlayback = false;

  @override
  void dispose() {
    if (_ownsPlayback) {
      _playback?.dispose();
    }
    super.dispose();
  }

  void _ensurePlaybackCreated() {
    if (_playback != null) return;
    if (widget.controller != null) {
      _playback = widget.controller;
      return;
    }
    _playback = MediaPlaybackController();
    _ownsPlayback = true;
  }

  /// [widget.controller] 非空时直接使用注入的会话，不建原生播放器。
  MediaPlaybackController? get _externalController => widget.controller;

  @override
  Widget build(BuildContext context) {
    final hasExternalController = widget.controller != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child:
              BlocSelector<
                VideoBloc,
                VideoState,
                ({MediaStream? stream, String? streamError})
              >(
                selector: (state) =>
                    (stream: state.mediaStream, streamError: state.streamError),
                builder: (context, data) {
                  if (data.streamError != null) {
                    return _ErrorView(message: data.streamError!);
                  }

                  final stream = data.stream;
                  if (stream == null) {
                    return const _LoadingView();
                  }

                  _ensurePlaybackCreated();
                  return _VideoSurface(controller: _playback!, stream: stream);
                },
              ),
        ),
        if (hasExternalController)
          _QueueControlBar(controller: _externalController!),
      ],
    );
  }
}

/// 播放队列控制条：下一首 / 上一首 / 循环播放模式切换。
///
/// 只调用 [MediaPlaybackController] 的队列 API，不改变播放器会话；
/// 队列状态（当前序号 / 长度）通过 [MediaPlaybackController.states]
/// 订阅后在按钮旁边以小字形式显示。
class const _QueueControlBar({
  required final MediaPlaybackController controller,
}) extends StatefulWidget {
  @override
  State<_QueueControlBar> createState() => _QueueControlBarState();
}

class _QueueControlBarState() extends State<_QueueControlBar> {
  StreamSubscription<PlaybackState>? _subscription;
  PlaybackState? _state;

  @override
  void initState() {
    super.initState();
    _subscription = widget.controller.states.listen((state) {
      if (!mounted) return;
      setState(() => _state = state);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final queueActive = state != null && state.queueLength > 0;
    final displayIndex = state?.currentIndex != null
        ? state!.currentIndex + 1
        : 0;
    final displayLength = state?.queueLength ?? 0;
    final currentQueueMode = state?.queueMode ?? PlaybackQueueMode.none;

    return Container(
      color: $styles.colors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: $styles.insets.sm,
        vertical: $styles.insets.xs,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: '上一首',
            iconSize: 22,
            color: $styles.colors.onSurfaceVariant,
            onPressed: queueActive
                ? () {
                    HapticFeedback.lightImpact();
                    widget.controller.previous();
                  }
                : null,
            icon: Icon(Icons.skip_previous),
          ),
          IconButton(
            tooltip: '下一首',
            iconSize: 22,
            color: $styles.colors.onSurfaceVariant,
            onPressed: queueActive
                ? () {
                    HapticFeedback.lightImpact();
                    widget.controller.next();
                  }
                : null,
            icon: Icon(Icons.skip_next),
          ),
          Gap($styles.insets.xs),
          IconButton(
            tooltip: _queueModeTooltip(context, currentQueueMode),
            iconSize: 20,
            color: $styles.colors.onSurfaceVariant,
            onPressed: queueActive
                ? () {
                    HapticFeedback.lightImpact();
                    widget.controller.setQueueMode(
                      _nextQueueMode(currentQueueMode),
                    );
                  }
                : null,
            icon: Icon(_queueModeIcon(currentQueueMode)),
          ),
          const Spacer(),
          if (queueActive)
            Text(
              '$displayIndex / $displayLength',
              style: $styles.text.bodySmall.copyWith(
                color: $styles.colors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  PlaybackQueueMode _nextQueueMode(PlaybackQueueMode current) {
    switch (current) {
      case PlaybackQueueMode.none:
        return PlaybackQueueMode.single;
      case PlaybackQueueMode.single:
        return PlaybackQueueMode.loop;
      case PlaybackQueueMode.loop:
        return PlaybackQueueMode.none;
    }
  }

  String _queueModeTooltip(BuildContext context, PlaybackQueueMode mode) {
    final l10n = AppLocalizations.of(context);
    switch (mode) {
      case PlaybackQueueMode.none:
        return l10n?.queueModeNone ?? '循环：关闭';
      case PlaybackQueueMode.single:
        return l10n?.queueModeSingle ?? '单首循环';
      case PlaybackQueueMode.loop:
        return l10n?.queueModeLoop ?? '队列循环';
    }
  }

  IconData _queueModeIcon(PlaybackQueueMode mode) {
    switch (mode) {
      case PlaybackQueueMode.none:
        return Icons.repeat;
      case PlaybackQueueMode.single:
        return Icons.repeat_one;
      case PlaybackQueueMode.loop:
        return Icons.repeat;
    }
  }
}

/// 持有播放器并驱动单条媒体打开。
///
/// 独立为 [StatefulWidget] 是为了让 `open` 只在 [MediaStream] 变化时触发，
/// 而不是随父级 [BlocSelector] 的每次重建重放。
class const _VideoSurface({
  required final MediaPlaybackController controller,
  required final MediaStream stream,
}) extends StatefulWidget {
  @override
  State<_VideoSurface> createState() => _VideoSurfaceState();
}

class _VideoSurfaceState() extends State<_VideoSurface> {
  StreamSubscription<PlaybackState>? _subscription;
  PlaybackState? _playbackState;
  late final BoostRateController _boost;
  late final BrightnessService _brightnessService;
  bool _fullscreen = false;

  @override
  void initState() {
    super.initState();
    _boost = BoostRateController(widget.controller);
    _brightnessService = BrightnessService();
    _subscription = widget.controller.states.listen((state) {
      if (!mounted) return;
      setState(() => _playbackState = state);
    });
    widget.controller.open(widget.stream);
    _restoreSavedRate();
    _applyPreferredQuality();
  }

  /// 套用上次记住的默认倍速。
  ///
  /// PreferencesDataSource 由页面级注入；单独使用本组件的 widget 测试
  /// 没有该注入，此时跳过（只影响默认倍速记忆，不影响当次播放）。
  Future<void> _restoreSavedRate() async {
    try {
      final result = await context.read<PreferencesDataSource>().get(
        PreferencesKey.playbackRate,
      );
      if (!mounted) return;
      switch (result) {
        case Ok(:final value):
          if (value != 1.0) {
            unawaited(widget.controller.setRate(value));
          }
        case Error():
          break;
      }
    } catch (_) {}
  }

  /// 套用上次记住的默认画质。
  ///
  /// 只在记住的高度与当前流不同时重新解析一次；流已在该高度时什么也不做。
  /// 无 PreferencesDataSource / VideoDetailRepository 注入时跳过。
  Future<void> _applyPreferredQuality() async {
    try {
      final result = await context.read<PreferencesDataSource>().get(
        PreferencesKey.preferredQualityHeight,
      );
      if (!mounted) return;
      switch (result) {
        case Ok(:final value):
          final preferredHeight = value;
          if (preferredHeight == null) return;
          if (preferredHeight == widget.stream.height) return;
          final videoId = context.read<VideoBloc>().state.videoDetail?.video.id;
          if (videoId == null) return;
          final repository = context.read<VideoDetailRepository>();
          unawaited(
            repository
                .getMediaStream(videoId, preferHeight: preferredHeight)
                .then((result) {
                  if (!mounted) return;
                  switch (result) {
                    case Ok(:final value):
                      widget.controller.restorePositionSeconds =
                          widget.controller.state.position.inSeconds;
                      unawaited(widget.controller.open(value));
                      context.read<VideoBloc>().add(MediaStreamChanged(value));
                    case Error():
                      break;
                  }
                }),
          );
        case Error():
          break;
      }
    } catch (_) {}
  }

  /// 全屏：横屏 + 沉浸系统 UI；退出时恢复竖屏与边缘到边缘。
  ///
  /// 不改页面布局，方向由系统响应；SystemChrome 在测试环境无效但不报错。
  Future<void> _toggleFullscreen() async {
    setState(() => _fullscreen = !_fullscreen);
    if (_fullscreen) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void didUpdateWidget(covariant _VideoSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stream != oldWidget.stream) {
      widget.controller.open(widget.stream);
    }
  }

  @override
  void dispose() {
    _boost.dispose();
    _subscription?.cancel();
    if (_fullscreen) {
      // 离开时若仍处全屏，恢复竖屏，避免带着横屏设置回到列表页。
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _playbackState;
    final hasError = state != null && state.error != null;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: PlayerGestureLayer(
            controller: widget.controller,
            brightnessService: _brightnessService,
            boost: _boost,
            child: Video(controller: widget.controller.videoController),
          ),
        ),
        Positioned(
          top: $styles.insets.xs,
          right: $styles.insets.xs,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SleepTimerChip(controller: widget.controller),
              const Gap(6),
              QualityPickerChip(
                controller: widget.controller,
                stream: widget.stream,
              ),
              const Gap(6),
              PlaybackSpeedChip(controller: widget.controller),
              const Gap(6),
              _FullscreenButton(
                fullscreen: _fullscreen,
                onPressed: _toggleFullscreen,
              ),
            ],
          ),
        ),
        ListenableBuilder(
          listenable: _boost,
          builder: (context, _) => _boost.boosted
              ? const Positioned(bottom: 16, child: _BoostBadge())
              : const SizedBox.shrink(),
        ),
        if (hasError)
          Positioned.fill(
            child: _ErrorView(
              message: state.error!,
              onRetry: () => widget.controller.retry(widget.stream),
            ),
          ),
      ],
    );
  }
}

class const _LoadingView() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: $styles.colors.scrim,
      alignment: Alignment.center,
      child: CircularProgressIndicator(color: $styles.colors.accentFill),
    );
  }
}

class const _ErrorView({
  required final String message,
  final VoidCallback? onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: $styles.colors.scrim,
      alignment: Alignment.center,
      padding: EdgeInsets.all($styles.insets.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: $styles.colors.onScrim, size: 32),
          const Gap(8),
          Text(
            '播放失败：$message',
            textAlign: TextAlign.center,
            style: $styles.text.bodySmall.copyWith(
              color: $styles.colors.onScrim,
            ),
          ),
          if (onRetry != null) ...[
            const Gap(8),
            TextButton(
              onPressed: onRetry,
              child: Text(
                '重试',
                style: $styles.text.bodySmall.copyWith(
                  color: $styles.colors.accentText,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 长按 2x 期间的临时标记。
class const _BoostBadge() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: $styles.colors.scrim.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '2x',
        style: $styles.text.bodySmall.copyWith(color: $styles.colors.onScrim),
      ),
    );
  }
}

/// 全屏 / 退出全屏按钮。
class const _FullscreenButton({
  required final bool fullscreen,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: $styles.colors.scrim.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            size: 18,
            color: $styles.colors.onScrim,
          ),
        ),
      ),
    );
  }
}

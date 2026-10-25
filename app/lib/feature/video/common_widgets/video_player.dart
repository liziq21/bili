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
import '../../setting/app_settings.dart';
import 'playback_speed_chip.dart';
import 'player_gesture_layer.dart';
import 'player_keyboard_shortcuts.dart';
import 'quality_picker_chip.dart';
import 'sleep_timer_chip.dart';
import '../danmaku/danmaku_overlay.dart';
import '../../../l10n/localization_file/app_localizations.dart';
import '../../../main.dart';
import '../bloc/queue_bloc.dart';
import '../bloc/video_bloc.dart';
import 'playback_queue_view.dart';
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

  /// 页面级队列接管媒体加载时为 true，避免将队列重置成单条媒体。
  final bool queueManaged = false,

  /// 是否铺满所在区域（全屏）。
  ///
  /// 由页面持有而非本组件自持：铺满需要父级把本组件放进 [Expanded]，那是
  /// 页面布局的决定。本组件只按该标志切换「16:9 内嵌」与「铺满」两种布局。
  final bool fullscreen = false,

  /// 进入 / 退出全屏。横屏与系统 UI 的切换由页面负责。
  final VoidCallback? onToggleFullscreen,

  /// 最小化：退出全屏并暂停播放，保留播放位置。
  final VoidCallback? onMinimize,

  /// 画面构建器，缺省渲染原生 [Video]。
  ///
  /// 真 [Video] 依赖平台 Texture Registry 与 libmpv OpenGL，widget 测试里
  /// 渲染会挂住 pump，故测试经此参数注入纯 Flutter 画面，只测外围交互。
  final Widget Function(MediaPlaybackController controller)? surfaceBuilder,
}) extends StatefulWidget {
  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState() extends State<VideoPlayer> {
  MediaPlaybackController? _playback;

  /// 是否由本组件创建（进而由本组件释放），区别于外部注入的会话。
  bool _ownsPlayback = false;

  /// 全屏下控制层是否展开。内嵌态恒展开，不做自动隐藏。
  bool _controlsVisible = true;

  /// 全屏下控制层的自动收起定时器。
  Timer? _autoHideControls;

  /// 全屏时展开控制层后多久自动收起。
  static const Duration _autoHideDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    // 首次构建就处于全屏时同样先收起控制层，与切换进来的路径保持一致。
    _controlsVisible = !widget.fullscreen;
  }

  @override
  void didUpdateWidget(covariant VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fullscreen == widget.fullscreen) return;
    // 进全屏先收起控制层（画面要干净），退出全屏恢复常显。
    _controlsVisible = !widget.fullscreen;
    _scheduleAutoHide();
  }

  @override
  void dispose() {
    _autoHideControls?.cancel();
    if (_ownsPlayback) {
      _playback?.dispose();
    }
    super.dispose();
  }

  /// 全屏下单击画面：展开则安排自动收起，收起则直接展开。
  void _toggleControls() {
    if (!widget.fullscreen) return;
    setState(() => _controlsVisible = !_controlsVisible);
    _scheduleAutoHide();
  }

  /// 重新计时：全屏且控制层展开时，到点自动收起。
  void _scheduleAutoHide() {
    _autoHideControls?.cancel();
    if (!widget.fullscreen || !_controlsVisible) return;
    _autoHideControls = Timer(_autoHideDelay, () {
      if (!mounted) return;
      setState(() => _controlsVisible = false);
    });
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

  /// 画面本体：按播放态选错误 / 加载 / 播放器表面。
  Widget _surface() =>
      BlocSelector<
        VideoBloc,
        VideoState,
        ({MediaStream? stream, String? streamError})
      >(
        selector: (state) =>
            (stream: state.mediaStream, streamError: state.streamError),
        builder: (context, data) {
          if (data.streamError != null) {
            final errorView = _ErrorView(message: data.streamError!);
            return widget.fullscreen
                ? errorView
                : AspectRatio(
                    aspectRatio: widget.aspectRatio,
                    child: errorView,
                  );
          }

          final stream = data.stream;
          if (stream == null) {
            const loadingView = _LoadingView();
            return widget.fullscreen
                ? loadingView
                : AspectRatio(
                    aspectRatio: widget.aspectRatio,
                    child: loadingView,
                  );
          }

          _ensurePlaybackCreated();
          final surface = _VideoSurface(
            controller: _playback!,
            stream: stream,
            fullscreen: widget.fullscreen,
            controlsVisible: _controlsVisible,
            onToggleFullscreen: widget.onToggleFullscreen,
            onMinimize: widget.onMinimize,
            onTapSurface: _toggleControls,
            queueManaged: widget.queueManaged,
            surfaceBuilder: widget.surfaceBuilder,
          );

          if (widget.fullscreen) return surface;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(aspectRatio: widget.aspectRatio, child: surface),
              _PlayerControlBar(
                controller: _playback!,
                stream: stream,
                fullscreen: false,
                onToggleFullscreen: widget.onToggleFullscreen,
              ),
            ],
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final surface = _surface();
    if (widget.fullscreen || widget.controller == null) return surface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        surface,
        _QueueControlBar(controller: widget.controller!),
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
    final l10n = AppLocalizations.of(context);
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
            tooltip: l10n?.previousItem ?? 'Previous',
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
            tooltip: l10n?.nextItem ?? 'Next',
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
            tooltip: _queueModeTooltip(l10n, currentQueueMode),
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

  String _queueModeTooltip(AppLocalizations? l10n, PlaybackQueueMode mode) {
    switch (mode) {
      case PlaybackQueueMode.none:
        return l10n?.loopOff ?? 'Loop off';
      case PlaybackQueueMode.single:
        return l10n?.loopOne ?? 'Loop one';
      case PlaybackQueueMode.loop:
        return l10n?.loopQueue ?? 'Loop queue';
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
  required final bool fullscreen,
  required final bool controlsVisible,
  required final VoidCallback? onToggleFullscreen,
  required final VoidCallback? onMinimize,
  required final VoidCallback onTapSurface,
  required final bool queueManaged,
  required final Widget Function(MediaPlaybackController controller)?
  surfaceBuilder,
}) extends StatefulWidget {
  @override
  State<_VideoSurface> createState() => _VideoSurfaceState();
}

class _VideoSurfaceState() extends State<_VideoSurface> {
  StreamSubscription<PlaybackState>? _subscription;
  PlaybackState? _playbackState;
  GestureSettings _gestureSettings = const GestureSettings();
  late final BoostRateController _boost;
  late final BrightnessService _brightnessService;

  @override
  void initState() {
    super.initState();
    _boost = BoostRateController(widget.controller);
    _brightnessService = BrightnessService();
    _subscription = widget.controller.states.listen((state) {
      if (!mounted) return;
      setState(() => _playbackState = state);
    });
    if (!widget.queueManaged) widget.controller.open(widget.stream);
    _restoreSavedRate();
    _applyPreferredQuality();
    _loadGestureSettings();
  }

  Future<void> _loadGestureSettings() async {
    try {
      final settings = await GestureSettings.load(
        context.read<PreferencesDataSource>(),
      );
      if (!mounted) return;
      setState(() => _gestureSettings = settings);
    } on Object catch (_) {}
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
  /// 整档记忆：先读源侧清晰度 id 精确匹配，id 缺失或源里已不存在该档时退回
  /// 记住的高度。当前流已是目标档时什么也不做，不重复解析。
  /// 无 PreferencesDataSource / VideoDetailRepository 注入时跳过。
  Future<void> _applyPreferredQuality() async {
    try {
      final preferences = context.read<PreferencesDataSource>();
      int? preferredHeight;
      int? preferredStreamId;
      final heightResult = await preferences.get(
        PreferencesKey.preferredQualityHeight,
      );
      if (!mounted) return;
      switch (heightResult) {
        case Ok(:final value):
          preferredHeight = value;
        case Error():
          break;
      }
      final streamIdResult = await preferences.get(
        PreferencesKey.preferredQualityStreamId,
      );
      if (!mounted) return;
      switch (streamIdResult) {
        case Ok(:final value):
          preferredStreamId = value;
        case Error():
          break;
      }
      if (preferredHeight == null && preferredStreamId == null) return;
      // 当前已在目标档：id 相同即同一档，缺 id 时退回按高度比。
      if (preferredStreamId != null &&
          widget.stream.streamId == preferredStreamId) {
        return;
      }
      if (preferredStreamId == null &&
          preferredHeight == widget.stream.height) {
        return;
      }
      final videoId = context.read<VideoBloc>().state.videoDetail?.video.id;
      if (videoId == null) return;
      final repository = context.read<VideoDetailRepository>();
      unawaited(
        repository
            .getMediaStream(
              videoId,
              preferHeight: preferredHeight,
              preferStreamId: preferredStreamId,
            )
            .then((result) {
              if (!mounted) return;
              switch (result) {
                case Ok(:final value):
                  widget.controller.restorePositionSeconds =
                      widget.controller.state.position.inSeconds;
                  final queue = context.read<QueueBloc?>();
                  if (queue != null) {
                    queue.updateCurrentStream(value);
                  } else {
                    unawaited(widget.controller.open(value));
                  }
                  context.read<VideoBloc>().add(MediaStreamChanged(value));
                case Error():
                  break;
              }
            }),
      );
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant _VideoSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stream != oldWidget.stream && !widget.queueManaged) {
      widget.controller.open(widget.stream);
    }
  }

  @override
  void dispose() {
    _boost.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _playbackState;
    final hasError = state != null && state.error != null;
    final videoId = context.select<VideoBloc, String?>(
      (bloc) => bloc.state.videoDetail?.video.id,
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: PlayerGestureLayer(
            controller: widget.controller,
            brightnessService: _brightnessService,
            boost: _boost,
            seekEnabled: _gestureSettings.seekEnabled,
            volumeEnabled: _gestureSettings.volumeEnabled,
            brightnessEnabled: _gestureSettings.brightnessEnabled,
            boostEnabled: _gestureSettings.boostEnabled,
            onTap: widget.fullscreen ? widget.onTapSurface : null,
            onDoubleTapScreen: widget.onToggleFullscreen,
            child: PlayerKeyboardShortcuts(
              controller: widget.controller,
              onToggleFullscreen: widget.onToggleFullscreen,
              child:
                  widget.surfaceBuilder?.call(widget.controller) ??
                  Video(controller: widget.controller.videoController),
            ),
          ),
        ),
        if (videoId != null)
          DanmakuOverlay(controller: widget.controller, videoId: videoId),
        if (widget.fullscreen && widget.controlsVisible)
          Positioned(
            top: $styles.insets.xs,
            right: $styles.insets.xs,
            child: _PlayerControlBar(
              controller: widget.controller,
              stream: widget.stream,
              fullscreen: true,
              onToggleFullscreen: widget.onToggleFullscreen,
              onMinimize: widget.onMinimize,
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

/// 播放器操作栏。
///
/// 内嵌模式下放在视频画面下方，避免控制项遮挡视频；全屏模式下仍作为
/// 可自动隐藏的浮层显示，因为全屏播放器没有可供控制栏占用的额外布局空间。
class const _PlayerControlBar({
  required final MediaPlaybackController controller,
  required final MediaStream stream,
  required final bool fullscreen,
  required final VoidCallback? onToggleFullscreen,
  final VoidCallback? onMinimize,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <Widget>[
      SleepTimerChip(controller: controller),
      QualityPickerChip(controller: controller, stream: stream),
      PlaybackSpeedChip(controller: controller),
      if (context.read<QueueBloc?>() case final queue?)
        IconButton(
          tooltip: l10n?.playbackQueueTitle ?? 'Playback queue',
          iconSize: 22,
          color: fullscreen
              ? $styles.colors.onScrim
              : $styles.colors.onSurfaceVariant,
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => BlocProvider.value(
              value: queue,
              child: const PlaybackQueueView(),
            ),
          ),
          icon: const Icon(Icons.queue_music),
        ),
      _FullscreenButton(fullscreen: fullscreen, onPressed: onToggleFullscreen),
      if (fullscreen && onMinimize != null)
        _OverlayIconButton(
          icon: Icons.picture_in_picture_alt,
          tooltip: l10n?.minimize ?? 'Minimize',
          onPressed: () {
            HapticFeedback.lightImpact();
            onMinimize!();
          },
        ),
    ];

    if (fullscreen) {
      return Row(mainAxisSize: MainAxisSize.min, children: _withGaps(items));
    }

    return Container(
      color: $styles.colors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: $styles.insets.sm,
        vertical: $styles.insets.xs,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Wrap(spacing: 6, runSpacing: 6, children: items),
      ),
    );
  }

  List<Widget> _withGaps(List<Widget> items) {
    final result = <Widget>[];
    for (final item in items) {
      if (result.isNotEmpty) result.add(const Gap(6));
      result.add(item);
    }
    return result;
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
    final l10n = AppLocalizations.of(context);
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
            l10n?.playbackFailed(message) ?? 'Playback failed: $message',
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
                l10n?.retry ?? 'Retry',
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
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _OverlayIconButton(
      icon: fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
      tooltip: fullscreen
          ? (l10n?.back ?? 'Back')
          : (l10n?.fullscreen ?? 'Fullscreen'),
      onPressed: onPressed == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPressed!();
            },
    );
  }
}

/// 画面浮层上的图标按钮：半透明圆角底 + 点击态。
class const _OverlayIconButton({
  required final IconData icon,
  required final String tooltip,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: $styles.colors.scrim.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 18, color: $styles.colors.onScrim),
          ),
        ),
      ),
    );
  }
}

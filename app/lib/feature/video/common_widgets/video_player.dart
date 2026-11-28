import 'dart:async';
import 'dart:math' as math;

import 'package:data/data.dart';
import 'package:flutter/rendering.dart';
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
import '../../../design/design.dart';
import '../../../domain/sleep_timer_action.dart';
import '../../notification/sleep_timer_notifier.dart';
import '../../setting/app_settings.dart';
import 'playback_speed_chip.dart';
import 'player_gesture_layer.dart';
import 'player_keyboard_shortcuts.dart';
import 'playback_queue_sheet.dart';
import 'quality_picker_chip.dart';
import 'sleep_timer_chip.dart';
import '../danmaku/danmaku_overlay.dart';
import '../../../l10n/localization_file/app_localizations.dart';
import '../../../main.dart';
import '../bloc/video_bloc.dart';
import '../video_queue_request.dart';
import '../player/playback_error_label.dart';
import '../player/brightness_service.dart';
import '../player/media_playback_controller.dart';
import '../player/playback_error.dart';

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

  /// 画面显示比例。null 表示跟随视频自身尺寸（由播放器解出的
  /// `videoParams` 决定），解出之前按 16:9 占位。
  ///
  /// 竖屏/方形投稿必须走这个缺省：容器写死 16:9 时，非 16:9 的画面只能在
  /// 容器里 contain 成很小的一块，四周全是黑边。
  final double? aspectRatio,

  /// 播放器会话，为 null 时组件自建并在销毁时释放。
  ///
  /// 测试用它注入假实现：真实的 [MediaPlaybackController] 会初始化原生库，
  /// 在 widget 测试环境里起不来。
  final MediaPlaybackController? controller,

  /// 是否铺满所在区域（全屏）。
  ///
  /// 由页面持有而非本组件自持：铺满需要父级把本组件放进 [Expanded]，那是
  /// 页面布局的决定。本组件只按该标志切换「按视频比例内嵌」与「铺满」两种
  /// 布局：内嵌时容器比例跟随视频（竖屏/方形不再被塞进 16:9），只有视频
  /// 比例尚未解出时才按 16:9 占位。
  final bool fullscreen = false,

  /// 桌面端方向键的普通 / Shift 快进步长。
  final Duration keyboardSeekStep = kKeyboardSeekStep,
  final Duration keyboardSeekStepWithShift = kKeyboardSeekStepLong,

  /// 进入 / 退出全屏。横屏与系统 UI 的切换由页面负责。
  final VoidCallback? onToggleFullscreen,

  /// 重新解析播放地址。用于媒体地址在播放器打开前就失败的情况。
  final VoidCallback? onRetry,

  /// 最小化：退出全屏并暂停播放，保留播放位置。
  final VoidCallback? onMinimize,

  /// 睡眠定时器到点选择「关闭播放器」时调用，通常是页面的返回入口。
  final VoidCallback? onExit,

  /// 画面构建器，缺省渲染原生 [Video]。
  ///
  /// 真 [Video] 依赖平台 Texture Registry 与 libmpv OpenGL，widget 测试里
  /// 渲染会挂住 pump，故测试经此参数注入纯 Flutter 画面，只测外围交互。
  final Widget Function(MediaPlaybackController controller)? surfaceBuilder,

  /// 已解析的播放队列。非空时以队列方式起播，而不是只播当前这一条。
  ///
  /// 解析在页面层完成（需要 repository 与失败跳过），播放层只接收结果。
  final VideoQueueResult? queue,
}) extends StatefulWidget {
  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState() extends State<VideoPlayer> {
  MediaPlaybackController? _playback;

  /// 播放器解出的视频比例；未知时为 null。
  double? _videoAspectRatio;
  StreamSubscription<double?>? _aspectRatioSubscription;

  /// 容器比例：显式指定优先，其次视频自身比例，最后退回 16:9。
  ///
  /// 播放器已经在解出尺寸时直接读它的当前值：组件晚于播放器挂载时（换页、
  /// 重建）不会收到之前那次广播，只订阅变化流会一直停在 16:9。
  double get _aspectRatio =>
      widget.aspectRatio ??
      _videoAspectRatio ??
      _playback?.videoAspectRatio ??
      16 / 9;

  /// 竖屏/方形内容在无高度约束时的高度上限（视口占比）。
  ///
  /// 没有这条上限时，竖屏视频按宽度撑出的高度会是宽度的一倍多，把下方简介
  /// 与评论挤出屏幕。
  static const double _portraitHeightFraction = 0.6;

  /// 内嵌播放器可用高度低于此值时不显示进度条。
  ///
  /// 控制栏不参与压缩，进度行约占 40，按钮行约占 56；再留约 100 给画面，
  /// 低于 200 时加上进度行就会把画面压到 0 高。
  static const double _minHeightForProgressBar = 200;

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
    _aspectRatioSubscription?.cancel();
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
    } else {
      _playback = MediaPlaybackController();
      _ownsPlayback = true;
    }
    _watchAspectRatio(_playback!);
  }

  /// 跟随播放器解出的视频比例重建布局。
  void _watchAspectRatio(MediaPlaybackController controller) {
    _aspectRatioSubscription ??= controller.videoAspectRatios.listen((ratio) {
      if (!mounted || ratio == _videoAspectRatio) return;
      setState(() => _videoAspectRatio = ratio);
    });
  }

  /// 画面本体：按播放态选错误 / 加载 / 播放器表面。
  Widget _surface() =>
      BlocSelector<
        VideoBloc,
        VideoState,
        ({
          MediaStream? stream,
          String? streamError,
          String? videoId,
          String? title,
          String? creatorName,
          String? thumbnailUrl,
        })
      >(
        selector: (state) {
          final video = state.videoDetail?.video;
          return (
            stream: state.mediaStream,
            streamError: state.streamError,
            videoId: video?.id,
            title: video?.title,
            creatorName: video?.creatorProfileName,
            thumbnailUrl: video?.thumbnailUrl,
          );
        },
        builder: (context, data) {
          if (data.streamError != null) {
            final errorView = _ErrorView(
              error: MediaPlaybackException.fromMessage(data.streamError!),
              onRetry: widget.onRetry,
            );
            return widget.fullscreen
                ? errorView
                : AspectRatio(aspectRatio: _aspectRatio, child: errorView);
          }

          final stream = data.stream;
          if (stream == null) {
            const loadingView = _LoadingView();
            return widget.fullscreen
                ? loadingView
                : AspectRatio(aspectRatio: _aspectRatio, child: loadingView);
          }

          _ensurePlaybackCreated();
          final surface = _VideoSurface(
            controller: _playback!,
            stream: stream,
            videoId: data.videoId,
            title: data.title,
            creatorName: data.creatorName,
            thumbnailUrl: data.thumbnailUrl,
            fullscreen: widget.fullscreen,
            controlsVisible: _controlsVisible,
            keyboardSeekStep: widget.keyboardSeekStep,
            keyboardSeekStepWithShift: widget.keyboardSeekStepWithShift,
            onToggleFullscreen: widget.onToggleFullscreen,
            onMinimize: widget.onMinimize,
            onExit: widget.onExit,
            onTapSurface: _toggleControls,
            surfaceBuilder: widget.surfaceBuilder,
            queue: widget.queue,
            aspectRatio: _aspectRatio,
          );

          if (widget.fullscreen) return surface;

          return LayoutBuilder(
            builder: (context, constraints) {
              final showProgressBar =
                  !constraints.hasBoundedHeight ||
                  constraints.maxHeight >= _minHeightForProgressBar;
              final controls = _PlayerControlBar(
                controller: _playback!,
                stream: stream,
                fullscreen: false,
                showProgressBar: showProgressBar,
                onToggleFullscreen: widget.onToggleFullscreen,
                onExit: widget.onExit,
              );
              // 画面与控制栏共用同一条宽度线：画面按可用高度收缩后，控制栏
              // 跟着画面一起变窄，而不是铺满整个播放器方块。否则画面居中带
              // 黑边时，进度条会横跨整屏、时间码落在黑边上。
              final maxVideoHeight = constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  // 高度不设限（页面在滚动容器里）时，竖屏/方形画面按视口占比
                  // 封顶，否则宽度撑出的高度会把下方内容顶出屏幕。
                  : (_aspectRatio <= 1
                        ? MediaQuery.sizeOf(context).height *
                              _portraitHeightFraction
                        : null);
              // 宽度不受限时无法按可用宽度算比例，退回宽度驱动的老布局。
              if (!constraints.hasBoundedWidth) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AspectRatio(aspectRatio: _aspectRatio, child: surface),
                    controls,
                  ],
                );
              }
              // 高度上限容不下控制栏时（极矮窗口）控制栏会画到本框之外，
              // 裁剪避免它与下方内容重叠。
              return ClipRect(
                child: _EmbeddedPlayerLayout(
                  aspectRatio: _aspectRatio,
                  maxVideoHeight: maxVideoHeight,
                  children: [
                    ColoredBox(
                      color: $styles.colors.scrim,
                      child: AspectRatio(
                        aspectRatio: _aspectRatio,
                        child: surface,
                      ),
                    ),
                    controls,
                  ],
                ),
              );
            },
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final surface = _surface();
    final controller = widget.controller;
    final player = widget.fullscreen || controller == null
        ? surface
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 与内层画面同理：让页面给播放器设的高度上限能传到 16:9 画面。
              // 外层 Column 若不把 surface 设为 Flexible，非弹性子项会拿到无界高度，
              // 内层的 Flexible 就永远收不到这个上限。
              Flexible(child: surface),
              _QueueControlBar(controller: controller),
            ],
          );
    // 倒计时状态挂在这里而不是控制栏里：全屏切换与自动隐藏都会重建控制栏。
    if (controller == null) return player;
    return _SleepTimerHost(
      controller: controller,
      onExit: widget.onExit,
      child: player,
    );
  }
}

/// 在控制栏之外持有睡眠定时器，让倒计时跨全屏切换与自动隐藏存活。
class const _SleepTimerHost({
  required final MediaPlaybackController controller,
  required final VoidCallback? onExit,
  required final Widget child,
}) extends StatefulWidget {
  @override
  State<_SleepTimerHost> createState() => _SleepTimerHostState();
}

class _SleepTimerHostState() extends State<_SleepTimerHost> {
  late final SleepTimerController _timer;
  SleepTimerNotifier? _notifier;
  SleepTimerAction _defaultAction = SleepTimerAction.pauseNow;
  bool _userStarted = false;
  bool _permissionRequested = false;

  /// 本播放器独占的提醒 id，叠加播放器时互不影响。
  final int _notificationId = allocateSleepTimerNotificationId();

  @override
  void initState() {
    super.initState();
    _timer = SleepTimerController(
      widget.controller,
      onEndingSoon: _notifyEndingSoon,
      onExitPlayer: widget.onExit,
      onCanceled: _cancelNotification,
    );
    try {
      _notifier = context.read<SleepTimerNotifier>();
    } on Object catch (_) {}
    unawaited(_restoreDefault());
  }

  Future<void> _notifyEndingSoon() async {
    await _notifier?.notifyEndingSoon(id: _notificationId);
  }

  void _cancelNotification() {
    unawaited(_notifier?.cancel(id: _notificationId));
  }

  Future<void> _restoreDefault() async {
    final PreferencesDataSource preferences;
    try {
      preferences = context.read<PreferencesDataSource>();
    } on Object catch (_) {
      return;
    }
    final loaded = await PlayerSettings.load(preferences);
    if (!mounted) return;
    setState(() => _defaultAction = loaded.sleepTimerDefaultAction);
    if (_userStarted ||
        !isValidSleepTimerMinutes(loaded.sleepTimerDefaultMinutes)) {
      return;
    }
    _timer.start(
      loaded.sleepTimerDefaultMinutes,
      action: loaded.sleepTimerDefaultAction,
    );
    _requestPermission(loaded.sleepTimerDefaultAction);
  }

  /// 只有会真正停播的行为才申请通知权限；`afterCurrent` 不发提醒。
  void _requestPermission(SleepTimerAction action) {
    if (_permissionRequested || action == SleepTimerAction.afterCurrent) {
      return;
    }
    _permissionRequested = true;
    unawaited(_notifier?.requestPermission());
  }

  void _handleTimerStarted(SleepTimerAction action) {
    _userStarted = true;
    _requestPermission(action);
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SleepTimerScope(
    controller: _timer,
    defaultAction: _defaultAction,
    onTimerStarted: _handleTimerStarted,
    child: widget.child,
  );
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
  StreamSubscription<List<PlaybackQueueItem>>? _queueSubscription;
  PlaybackState? _state;
  List<PlaybackQueueItem> _queueItems = const [];

  @override
  void initState() {
    super.initState();
    _queueItems = widget.controller.queueItems;
    _subscription = widget.controller.states.listen((state) {
      if (!mounted) return;
      setState(() => _state = state);
    });
    _queueSubscription = widget.controller.queueItemStates.listen((items) {
      if (!mounted) return;
      setState(() => _queueItems = items);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _queueSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = _state;
    final queueActive =
        _queueItems.isNotEmpty || (state != null && state.queueLength > 0);
    final displayIndex = state?.currentIndex != null
        ? state!.currentIndex + 1
        : 0;
    final displayLength = _queueItems.isNotEmpty
        ? _queueItems.length
        : (state?.queueLength ?? 0);
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
            icon: Icon(AppIcons.skipPrevious),
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
            icon: Icon(AppIcons.skipNext),
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
          IconButton(
            tooltip: l10n?.playbackQueue ?? 'Playback queue',
            iconSize: 20,
            color: $styles.colors.onSurfaceVariant,
            onPressed: () =>
                showPlaybackQueueSheet(context, controller: widget.controller),
            icon: const Icon(AppIcons.queue),
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
        return AppIcons.repeatOff;
      case PlaybackQueueMode.single:
        return AppIcons.repeatOne;
      case PlaybackQueueMode.loop:
        return AppIcons.repeatQueue;
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
  final String? videoId,
  final String? title,
  final String? creatorName,
  final String? thumbnailUrl,
  required final bool fullscreen,
  required final bool controlsVisible,
  required final Duration keyboardSeekStep,
  required final Duration keyboardSeekStepWithShift,
  required final VoidCallback? onToggleFullscreen,
  required final VoidCallback? onMinimize,
  final VoidCallback? onExit,
  required final VoidCallback onTapSurface,
  required final Widget Function(MediaPlaybackController controller)?
  surfaceBuilder,
  final VideoQueueResult? queue,
  // 画面在容器内 contain 后的宽高比；弹幕浮层据此收缩到画面矩形。
  required final double aspectRatio,
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
    // 有队列时只开队列：先按单条 open 再被队列覆盖会让画面白闪一次，也会
    // 让首条进历史/进队列两次。
    if (!_openQueueIfNeeded()) {
      widget.controller.open(
        widget.stream,
        videoId: widget.videoId,
        title: widget.title,
        creatorName: widget.creatorName,
        thumbnailUrl: widget.thumbnailUrl,
      );
    }
    _restoreSavedRate();
    _applyPreferredQuality();
    _loadGestureSettings();
  }

  /// 把已解析的播放队列交给播放层，返回是否真的打开了队列。
  ///
  /// 队列只开一次：后续 [didUpdateWidget] 里标题/封面等元数据变化走
  /// `updateCurrentQueueItemMetadata`，不重新打开，否则每帧都会重建播放列表。
  bool _openQueueIfNeeded() {
    final queue = widget.queue;
    if (queue == null || queue.items.isEmpty) return false;
    final items = [
      for (final item in queue.items)
        PlaybackQueueItem(stream: item.stream, videoId: item.videoId),
    ];
    final start = queue.startIndex.clamp(0, items.length - 1).toInt();
    unawaited(widget.controller.openQueueItems(items, index: start));
    return true;
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
        case Success(:final success):
          if (success != 1.0) {
            unawaited(widget.controller.setRate(success));
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
        case Success(:final success):
          preferredHeight = success;
        case Error():
          break;
      }
      final streamIdResult = await preferences.get(
        PreferencesKey.preferredQualityStreamId,
      );
      if (!mounted) return;
      switch (streamIdResult) {
        case Success(:final success):
          preferredStreamId = success;
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
                case Success(:final success):
                  widget.controller.restorePositionSeconds =
                      widget.controller.state.position.inSeconds;
                  unawaited(
                    widget.controller.open(
                      success,
                      videoId: widget.videoId,
                      title: widget.title,
                      creatorName: widget.creatorName,
                      thumbnailUrl: widget.thumbnailUrl,
                    ),
                  );
                  context.read<VideoBloc>().add(MediaStreamChanged(success));
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
    // 队列后带到（页面异步解析完成后才传下来）：补开一次并结束，不先按单条
    // open。已是同一队列则不重开：openQueueItems 会清空进度与当前索引。
    if (widget.queue != null && !identical(widget.queue, oldWidget.queue)) {
      if (_openQueueIfNeeded()) return;
    }
    if (widget.stream != oldWidget.stream && widget.queue == null) {
      widget.controller.open(
        widget.stream,
        videoId: widget.videoId,
        title: widget.title,
        creatorName: widget.creatorName,
        thumbnailUrl: widget.thumbnailUrl,
      );
      return;
    }
    if (widget.videoId != oldWidget.videoId ||
        widget.title != oldWidget.title ||
        widget.creatorName != oldWidget.creatorName ||
        widget.thumbnailUrl != oldWidget.thumbnailUrl) {
      widget.controller.updateCurrentQueueItemMetadata(
        videoId: widget.videoId,
        title: widget.title,
        creatorName: widget.creatorName,
        thumbnailUrl: widget.thumbnailUrl,
      );
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
              seekStep: widget.keyboardSeekStep,
              seekStepWithShift: widget.keyboardSeekStepWithShift,
              onToggleFullscreen: widget.onToggleFullscreen,
              child:
                  widget.surfaceBuilder?.call(widget.controller) ??
                  Video(
                    controller: widget.controller.videoController,
                    // 画面按 contain 铺满容器：容器比例已跟随视频尺寸，
                    // 这里显式声明避免库的默认行为与容器比例打架。
                    fit: BoxFit.contain,
                  ),
            ),
          ),
        ),
        if (videoId != null)
          DanmakuOverlay(
            controller: widget.controller,
            videoId: videoId,
            aspectRatio: widget.aspectRatio,
          ),
        if (widget.fullscreen)
          Positioned(
            top: $styles.insets.xs,
            right: $styles.insets.xs,
            // 自动隐藏只把控制栏收起，不卸载：卸载会重建整条控制栏，
            // 里面的倒计时状态随之丢失。
            child: Visibility(
              visible: widget.controlsVisible,
              maintainState: true,
              child: _PlayerControlBar(
                controller: widget.controller,
                stream: widget.stream,
                fullscreen: true,
                onToggleFullscreen: widget.onToggleFullscreen,
                onMinimize: widget.onMinimize,
                onExit: widget.onExit,
              ),
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
              error: state.error!,
              isRetrying: state.isRetrying,
              onRetry: () => widget.controller.retry(
                widget.controller.currentStream ?? widget.stream,
              ),
              onSkip: _canSkip(state)
                  ? () => unawaited(widget.controller.next())
                  : null,
            ),
          ),
      ],
    );
  }

  bool _canSkip(PlaybackState state) =>
      state.queueLength > 0 && state.currentIndex < state.queueLength - 1;
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
  final VoidCallback? onExit,

  /// 内嵌模式下是否给进度条留一行。窗口矮到放不下「画面 + 两行控制」时由
  /// 调用方关掉，优先保住画面。
  final bool showProgressBar = true,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <Widget>[
      SleepTimerChip(controller: controller, onExit: onExit),
      QualityPickerChip(controller: controller, stream: stream),
      PlaybackSpeedChip(controller: controller),
      _FullscreenButton(fullscreen: fullscreen, onPressed: onToggleFullscreen),
      if (fullscreen && onMinimize != null)
        _OverlayIconButton(
          icon: AppIcons.pictureInPicture,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 内嵌播放器没有浮层控制区可挂进度条，所以进度条占控制栏的一行，
          // 与右侧的清晰度 / 倍速 / 全屏按钮分开（#665）。
          if (showProgressBar) _PlaybackProgressBar(controller: controller),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(spacing: 6, runSpacing: 6, children: items),
          ),
        ],
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

/// 内嵌播放器底部的进度条：当前时间 / 可拖动进度 / 总时长（#665）。
///
/// 自己订阅 [MediaPlaybackController.states]，让位置更新只重建这一行，不牵动
/// 整条控制栏。
///
/// 拖动期间由 [_dragMilliseconds] 接管显示，松手后继续由
/// [_pendingSeekMilliseconds] 接管，直到播放器回报的位置追到目标附近：seek
/// 是异步的，立刻放开会让滑块先跳回旧位置再跳回来。换片（时长变化）时旧目标
/// 直接丢弃，避免把上一段的目标 seek 到新媒体上。
class const _PlaybackProgressBar({
  required final MediaPlaybackController controller,
}) extends StatefulWidget {
  @override
  State<_PlaybackProgressBar> createState() => _PlaybackProgressBarState();
}

class _PlaybackProgressBarState() extends State<_PlaybackProgressBar> {
  /// seek 后位置回报与目标的允许偏差；播放器按关键帧对齐，不会精确落在目标上。
  static const _seekSettleTolerance = Duration(seconds: 1);

  /// seek 迟迟没有回报时放弃保持目标位置，回到播放器的真实位置。
  static const _seekSettleTimeout = Duration(seconds: 3);

  late PlaybackState _state = widget.controller.state;
  StreamSubscription<PlaybackState>? _subscription;
  Timer? _settleTimer;
  double? _dragMilliseconds;
  double? _pendingSeekMilliseconds;
  Duration? _dragDuration;

  @override
  void initState() {
    super.initState();
    _subscription = widget.controller.states.listen(_onState);
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  void _onState(PlaybackState state) {
    if (!mounted) return;
    setState(() {
      _state = state;
      if (_pendingSeekMilliseconds == null) return;
      // 时长变了说明换了媒体：旧拖动目标对新媒体没有意义。
      if (_dragDuration != null && state.duration != _dragDuration) {
        _clearSeek();
        return;
      }
      final drift = (state.position.inMilliseconds - _pendingSeekMilliseconds!)
          .abs();
      if (drift <= _seekSettleTolerance.inMilliseconds) _clearSeek();
    });
  }

  void _clearSeek() {
    _dragMilliseconds = null;
    _pendingSeekMilliseconds = null;
    _dragDuration = null;
    _settleTimer?.cancel();
    _settleTimer = null;
  }

  void _onDragStart(double value) {
    setState(() {
      _dragMilliseconds = value;
      _dragDuration = _state.duration;
    });
  }

  void _onDragEnd(double value) {
    if (_dragDuration != null && _state.duration != _dragDuration) {
      setState(_clearSeek);
      return;
    }
    setState(() => _pendingSeekMilliseconds = value);
    _settleTimer?.cancel();
    _settleTimer = Timer(
      _seekSettleTimeout,
      () => mounted ? setState(_clearSeek) : null,
    );
    unawaited(widget.controller.seek(Duration(milliseconds: value.round())));
  }

  @override
  Widget build(BuildContext context) {
    final total = _state.duration.inMilliseconds.toDouble();
    final playable = total > 0;
    final position =
        (_dragMilliseconds ??
                _pendingSeekMilliseconds ??
                _state.position.inMilliseconds.toDouble())
            .clamp(0.0, playable ? total : 0.0);
    // 等宽数字：时间从 0:09 走到 0:10 时标签宽度不变，滑块不会被挤动。
    // bodySmall 自带的 fontFeatures 要保留（copyWith 是替换而不是追加）。
    final labelStyle = $styles.text.bodySmall.copyWith(
      color: $styles.colors.onSurfaceVariant,
      fontFeatures: [
        ...?$styles.text.bodySmall.fontFeatures,
        const FontFeature.tabularFigures(),
      ],
    );
    return Row(
      children: [
        Text(_formatPosition(position), style: labelStyle),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: position,
              max: playable ? total : 1,
              onChanged: playable ? _onDragStart : null,
              onChangeEnd: playable ? _onDragEnd : null,
              semanticFormatterCallback: _formatPosition,
            ),
          ),
        ),
        Text(_formatPosition(total), style: labelStyle),
      ],
    );
  }
}

/// `m:ss`（不足一小时）或 `h:mm:ss`。
String _formatPosition(double milliseconds) {
  final seconds = math.max(0, (milliseconds / 1000).floor());
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final twoDigitSeconds = (seconds % 60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$twoDigitSeconds';
  }
  return '$minutes:$twoDigitSeconds';
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
  required final MediaPlaybackException error,
  final VoidCallback? onRetry,
  final VoidCallback? onSkip,
  final bool isRetrying = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final category = playbackErrorCategoryLabel(l10n, error.category);
    return Container(
      color: $styles.colors.scrim,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 播放器在矮视口里会被压到不足错误文案的自然高度。用可滚动容器 +
          // 最小高度居中，既保持居中观感，也不会再触发 RenderFlex 溢出。
          final minHeight = constraints.maxHeight.isFinite
              ? math.max(0.0, constraints.maxHeight - $styles.insets.md * 2)
              : 0.0;
          return SingleChildScrollView(
            padding: EdgeInsets.all($styles.insets.md),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppIcons.error,
                      color: $styles.colors.onScrim,
                      size: 32,
                    ),
                    const Gap(8),
                    Text(
                      category,
                      textAlign: TextAlign.center,
                      style: $styles.text.bodySmall.copyWith(
                        color: $styles.colors.onScrim,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      l10n?.videoLoadFailed ?? 'Playback failed',
                      textAlign: TextAlign.center,
                      style: $styles.text.bodySmall.copyWith(
                        color: $styles.colors.onScrim,
                      ),
                    ),
                    if (isRetrying) ...[
                      const Gap(8),
                      Text(
                        l10n?.playbackRetrying ?? 'Retrying...',
                        style: $styles.text.bodySmall.copyWith(
                          color: $styles.colors.onScrim,
                        ),
                      ),
                    ],
                    if (onRetry != null || onSkip != null) ...[
                      const Gap(8),
                      Wrap(
                        spacing: $styles.insets.sm,
                        alignment: WrapAlignment.center,
                        children: [
                          if (onRetry != null)
                            TextButton(
                              onPressed: onRetry,
                              child: Text(
                                l10n?.retry ?? 'Retry',
                                style: $styles.text.bodySmall.copyWith(
                                  color: $styles.colors.accentText,
                                ),
                              ),
                            ),
                          if (onSkip != null)
                            TextButton(
                              onPressed: onSkip,
                              child: Text(
                                l10n?.skip ?? 'Skip',
                                style: $styles.text.bodySmall.copyWith(
                                  color: $styles.colors.accentText,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
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
      icon: fullscreen ? AppIcons.fullscreenExit : AppIcons.fullscreen,
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
///
/// 视觉尺寸保持 30×30（18 图标 + 6 内边距），命中区扩到 44×44 以满足
/// WCAG 2.5.5；两者分离，放大触控目标不会让半透明底遮住更多画面。
class const _OverlayIconButton({
  required final IconData icon,
  required final String tooltip,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  static const double _visualSize = 30;
  static const double _tapTargetSize = 44;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: tooltip,
      // excludeSemantics 会丢弃 InkWell 的 tap 动作，必须在语义节点上声明。
      onTap: onPressed,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: SizedBox.square(
          dimension: _tapTargetSize,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Center(
                child: Material(
                  color: $styles.colors.scrim.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox.square(
                    dimension: _visualSize,
                    child: Center(
                      child: Icon(
                        icon,
                        size: 18,
                        color: $styles.colors.onScrim,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 内嵌播放器的两段式布局：画面在上、控制栏在下，两者共用同一条宽度线。
///
/// 画面在矮视口里按可用高度收缩后，宽度会小于整个播放器方块；控制栏必须
/// 跟着画面一起变窄，否则进度条会横跨整块区域、时间码落在画面外的留边上。
/// 控制栏宽度又取决于自身换行后的高度，所以宽度只能量出来，不能用固定常量。
class const _EmbeddedPlayerLayout({
  required final double aspectRatio,
  // 画面的高度上限；null 表示不限（宽度决定画面高度）。
  required final double? maxVideoHeight,
  required super.children,
}) extends MultiChildRenderObjectWidget {
  @override
  _RenderEmbeddedPlayerLayout createRenderObject(BuildContext context) =>
      _RenderEmbeddedPlayerLayout(aspectRatio, maxVideoHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderEmbeddedPlayerLayout renderObject,
  ) {
    if (renderObject.aspectRatio == aspectRatio &&
        renderObject.maxVideoHeight == maxVideoHeight) {
      return;
    }
    renderObject
      ..aspectRatio = aspectRatio
      ..maxVideoHeight = maxVideoHeight
      ..markNeedsLayout();
  }
}

class _RenderEmbeddedPlayerLayout(
  var double aspectRatio,
  var double? maxVideoHeight,
) extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  @override
  void performLayout() {
    final surface = firstChild!;
    final controls = childAfter(surface)!;
    final maxWidth = constraints.maxWidth;

    // 控制栏的换行由宽度决定，而画面宽度又取决于控制栏高度。先按整宽排一次
    // 拿到自然高度；只有缩到画面宽度后不会换行变高时，才把控制栏一起收窄。
    // 否则（竖屏画面、极矮的窗口）控制栏保持整宽，画面在它上方居中。
    controls.layout(BoxConstraints(maxWidth: maxWidth), parentUsesSize: true);
    final naturalControlsHeight = controls.size.height;
    var videoWidth = _videoWidthFor(maxWidth, naturalControlsHeight);
    if (videoWidth < maxWidth) {
      controls.layout(
        BoxConstraints.tightFor(width: videoWidth),
        parentUsesSize: true,
      );
      if (controls.size.height > naturalControlsHeight) {
        controls.layout(
          BoxConstraints(maxWidth: maxWidth),
          parentUsesSize: true,
        );
        videoWidth = _videoWidthFor(maxWidth, naturalControlsHeight);
      }
    }

    final videoHeight = aspectRatio > 0 ? videoWidth / aspectRatio : 0.0;
    surface.layout(
      BoxConstraints.tight(Size(videoWidth, videoHeight)),
      parentUsesSize: true,
    );

    final videoLeft = math.max(0.0, (maxWidth - videoWidth) / 2);
    final controlsLeft = math.max(0.0, (maxWidth - controls.size.width) / 2);
    (surface.parentData! as MultiChildLayoutParentData).offset = Offset(
      videoLeft,
      0,
    );
    (controls.parentData! as MultiChildLayoutParentData).offset = Offset(
      controlsLeft,
      videoHeight,
    );

    size = constraints.constrain(
      Size(maxWidth, videoHeight + controls.size.height),
    );
  }

  /// 高度受限时画面宽度 = （高度上限 - 控制栏高度）× 宽高比，且不超过可用宽度。
  double _videoWidthFor(double maxWidth, double controlsHeight) {
    final cap = maxVideoHeight;
    if (cap == null || !cap.isFinite) return maxWidth;
    final available = math.max(0.0, cap - controlsHeight);
    return math.min(maxWidth, available * aspectRatio);
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

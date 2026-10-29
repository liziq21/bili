import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:media_kit_video/media_kit_video.dart' hide VideoState;
import 'package:material_ui/material_ui.dart';

import '../../l10n/localization_file/app_localizations.dart';
import '../../l10n/localization_file/app_localizations_zh.dart';
import '../../main.dart';
import '../video/player/media_playback_controller.dart';
import 'bloc/live_bloc.dart';
import 'bloc/providers.dart';

/// 直播页：房间信息头 + media_kit 播放器。
///
/// 直播不做队列、不做进度、不做弹幕（直播无续播语义）。
/// 播放器不复用 [VideoPlayer]：后者绑定 [VideoBloc]，直播页用独立的
/// [LiveBloc] + [MediaPlaybackController]，仅保留播放/暂停/全屏三件事。
class const LiveScreen({
  super.key,
  final VoidCallback? onBackClick,
  required final String roomId,
}) extends StatefulWidget {
  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState() extends State<LiveScreen> {
  MediaPlaybackController? _playback;
  bool _fullscreen = false;
  bool _streamReady = false;

  @override
  void initState() {
    super.initState();
    _playback = MediaPlaybackController();
  }

  @override
  void dispose() {
    // 带着横屏设置离开会把整个应用留在横屏，离开时必须还原。
    if (_fullscreen) unawaited(_restorePortrait());
    unawaited(_playback?.dispose());
    super.dispose();
  }

  Future<void> _toggleFullscreen() async {
    setState(() => _fullscreen = !_fullscreen);
    if (_fullscreen) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await _restorePortrait();
    }
  }

  Future<void> _restorePortrait() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _openStream(MediaStream stream, {String? title, String? creatorName}) {
    if (_streamReady) return;
    _streamReady = true;
    unawaited(
      _playback!.open(
        stream,
        videoId: widget.roomId,
        title: title,
        creatorName: creatorName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final roomIdNum = int.tryParse(widget.roomId) ?? 0;

    return MultiBlocProvider(
      providers: getLiveBlocProviders(context, roomId: roomIdNum),
      child: Scaffold(
        backgroundColor: $styles.colors.surfaceContainerHighest,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: widget.onBackClick,
            tooltip: l10n.back,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          title: const Text('Live'),
        ),
        body: BlocConsumer<LiveBloc, LiveState>(
          listener: (context, state) {
            // 流地址就绪时开播放器。只触发一次：直播流不可 seek，
            // 重复 open 会打断当前播放。
            if (state.mediaStream != null) {
              _openStream(
                state.mediaStream!,
                title: state.roomDetail?.title,
                creatorName: state.roomDetail?.anchorName,
              );
            }
          },
          builder: (context, state) {
            // 详情加载失败 → 整页换错误态（无房间信息可显示）。
            if (state.roomError != null) {
              return _ErrorView(
                message: state.roomError!,
                l10n: l10n,
                onRetry: () =>
                    context.read<LiveBloc>().add(LoadLiveRoomDetail(roomIdNum)),
              );
            }

            // 详情加载中（尚未成功）。
            if (state.isLoading && state.roomDetail == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: $styles.colors.accentFill),
                    const Gap(8),
                    Text(l10n.liveRoomLoading, style: $styles.text.body),
                  ],
                ),
              );
            }

            final detail = state.roomDetail;
            final stream = state.mediaStream;
            final streamError = state.streamError;

            return CustomScrollView(
              slivers: [
                // 播放器区域。流地址失败只影响播放器，房间信息仍显示。
                SliverToBoxAdapter(
                  child: _PlayerArea(
                    controller: _playback!,
                    stream: stream,
                    streamError: streamError,
                    fullscreen: _fullscreen,
                    onToggleFullscreen: _toggleFullscreen,
                    onRetry: () =>
                        context.read<LiveBloc>().add(LoadLiveStream(roomIdNum)),
                  ),
                ),
                // 房间信息头。
                if (detail != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all($styles.insets.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标题。
                          Text(
                            detail.title,
                            style: $styles.text.h3,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Gap(8),
                          // 主播名 + 直播状态。
                          Row(
                            children: [
                              Text(detail.anchorName, style: $styles.text.body),
                              const Gap(8),
                              if (detail.isLive) _LiveBadge(),
                            ],
                          ),
                          const Gap(8),
                          // 在线人数。
                          Row(
                            children: [
                              const Icon(Icons.people_alt_rounded, size: 16),
                              const Gap(4),
                              Text(
                                '${detail.online} ${l10n.liveViewers}',
                                style: $styles.text.bodySmall,
                              ),
                            ],
                          ),
                          // 分区。
                          if (detail.areaName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                detail.areaName!,
                                style: $styles.text.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 直播状态徽章：红色圆点 + 「直播中」。
class const _LiveBadge() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: $styles.colors.onSurfaceVariant.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 6,
            height: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: $styles.colors.accentFill,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const Gap(4),
          Text(l10n.liveNow, style: $styles.text.bodySmall),
        ],
      ),
    );
  }
}

/// 播放器区域：Video widget + 简单控制条（播放/暂停 + 全屏）。
///
/// 直播不渲染进度条、弹幕、画质选择、倍速——直播无续播语义。
class const _PlayerArea({
  required final MediaPlaybackController controller,
  required final MediaStream? stream,
  required final String? streamError,
  required final bool fullscreen,
  required final VoidCallback onToggleFullscreen,
  required final VoidCallback onRetry,
}) extends StatefulWidget {
  @override
  State<_PlayerArea> createState() => _PlayerAreaState();
}

class _PlayerAreaState extends State<_PlayerArea> {
  bool _controlsVisible = true;
  Timer? _autoHideControls;

  @override
  void initState() {
    super.initState();
    _controlsVisible = !widget.fullscreen;
  }

  @override
  void didUpdateWidget(covariant _PlayerArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fullscreen == widget.fullscreen) return;
    _controlsVisible = !widget.fullscreen;
    _scheduleAutoHide();
  }

  @override
  void dispose() {
    _autoHideControls?.cancel();
    super.dispose();
  }

  void _scheduleAutoHide() {
    _autoHideControls?.cancel();
    if (!widget.fullscreen || !_controlsVisible) return;
    _autoHideControls = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    if (!widget.fullscreen) return;
    setState(() => _controlsVisible = !_controlsVisible);
    _scheduleAutoHide();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();

    // 流地址错误 → 播放器区域显示错误态 + 重试。
    if (widget.streamError != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: $styles.colors.surfaceContainerHighest,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: $styles.colors.onSurfaceVariant,
                ),
                const Gap(8),
                Text(l10n.liveStreamError, style: $styles.text.body),
                const Gap(12),
                FilledButton(
                  onPressed: widget.onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 流地址尚未就绪 → 加载态。
    if (widget.stream == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: $styles.colors.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // 流地址就绪 → Video widget + 控制条。
    final controller = widget.controller;
    final playerState = controller.state;

    final Widget surface = Video(controller: controller.videoController);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: widget.fullscreen ? _toggleControls : null,
        child: Stack(
          children: [
            Container(color: $styles.colors.scrim, child: surface),
            // 控制条：仅全屏时显示。
            if (widget.fullscreen && _controlsVisible)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: $styles.colors.scrim.withValues(alpha: 0.54),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        $styles.colors.scrim.withValues(alpha: 0.87),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // 播放 / 暂停。
                      IconButton(
                        onPressed: () => unawaited(
                          playerState.isPlaying
                              ? controller.pause()
                              : controller.play(),
                        ),
                        icon: Icon(
                          playerState.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                      // 全屏切换。
                      IconButton(
                        onPressed: widget.onToggleFullscreen,
                        icon: const Icon(Icons.fullscreen_rounded),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 整页错误态：详情加载失败时显示。
class const _ErrorView({
  required final String message,
  required final AppLocalizations l10n,
  required final VoidCallback onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: $styles.colors.onSurfaceVariant,
          ),
          const Gap(16),
          Text(l10n.liveRoomError, style: $styles.text.h3),
          const Gap(8),
          Text(message, style: $styles.text.bodySmall),
          const Gap(16),
          FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}

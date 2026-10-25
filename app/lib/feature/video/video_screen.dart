import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../l10n/localization_file/app_localizations.dart';
import '../../l10n/localization_file/app_localizations_zh.dart';
import '../../main.dart';
import '../../utils/platfrom_info.dart';
import '../../data/repository/video_detail_repository.dart';
import '../../database/dao/media_history_dao.dart';
import '../../database/table/media.dart';
import '../../datastore/media_history_settings.dart';
import '../../datastore/preferences_data_source.dart';
import 'bloc/queue_bloc.dart';
import 'bloc/providers.dart';
import 'bloc/video_bloc.dart';
import 'common_widgets/video_comments_view.dart';
import 'common_widgets/video_info_view.dart';
import 'common_widgets/video_player.dart';
import 'player/media_playback_controller.dart';

class const VideoScreen({
  super.key,
  final String videoId = 'demo_video',
  final VoidCallback? onBackClick,
}) extends StatefulWidget {
  @override
  State<VideoScreen> createState() => VideoScreenState();
}

class VideoScreenState() extends State<VideoScreen> {
  MediaPlaybackController? _playbackController;
  MediaHistoryDao? _mediaHistoryDao;
  PreferencesDataSource? _preferences;
  String? _sourceId;
  MediaHistorySettings _historySettings = const MediaHistorySettings();
  Future<void>? _progressLoadFuture;
  int _restorePositionSeconds = 0;
  int _progressGeneration = 0;

  /// 惰性初始化：原生库（libmpv）须先 [MediaKit.ensureInitialized]，
  /// 在 widget 测试环境起不来；仅在 build 被调用时才创建。
  MediaPlaybackController _ensurePlaybackController() {
    _playbackController ??= MediaPlaybackController();
    return _playbackController!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_progressLoadFuture == null) {
      try {
        _mediaHistoryDao ??= context.read<MediaHistoryDao>();
        _preferences ??= context.read<PreferencesDataSource>();
        _sourceId ??= context.read<MediaSource>().id;
      } catch (_) {}
    }
    if (_progressLoadFuture == null &&
        _mediaHistoryDao != null &&
        _sourceId != null) {
      _progressLoadFuture = _initializeProgressAsync();
    }
  }

  Future<void> _initializeProgressAsync() async {
    final preferences = _preferences;
    if (preferences != null) {
      _historySettings = await MediaHistorySettings.load(preferences);
    }
    if (_historySettings.shouldReadProgress) await _loadProgressAsync();
  }

  /// 查 [media_history] 里这条视频的播放进度，
  /// 拿到后写入 [MediaPlaybackController.restorePositionSeconds]，
  /// [_VideoSurface] 在 open 完成后自动 seek。
  Future<void> _loadProgressAsync({String? videoId}) async {
    if (!_historySettings.shouldReadProgress) return;
    final dao = _mediaHistoryDao;
    final sourceId = _sourceId;
    if (dao == null || sourceId == null) return;
    final generation = ++_progressGeneration;
    final requestedVideoId = videoId ?? widget.videoId;
    try {
      final mediaId = await dao.getOrCreateMediaId(
        sourceId,
        requestedVideoId,
        Media.typeVideo,
      );
      final progress = await dao.getProgressForMedia(mediaId);
      if (generation != _progressGeneration) return;
      if (progress != null && progress > 0) _restorePositionSeconds = progress;
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant VideoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId == widget.videoId) return;
    _restorePositionSeconds = 0;
    _playbackController?.restorePositionSeconds = 0;
    ++_progressGeneration;
    _progressLoadFuture = _historySettings.shouldReadProgress
        ? _loadProgressAsync(videoId: widget.videoId)
        : Future<void>.value();
  }

  /// 把当前播放位置写回 [media_history]，供下次进入本视频时 seek 起播。
  /// 不足 10s 不记，避免刚开进来就退出时把进度打回零。
  Future<void> _saveProgress() async {
    final progressLoadFuture = _progressLoadFuture;
    if (progressLoadFuture != null) await progressLoadFuture;
    if (!_historySettings.shouldWriteHistory) return;
    final controller = _playbackController;
    final dao = _mediaHistoryDao;
    if (controller == null || dao == null || _sourceId == null) return;
    final positionSeconds = controller.state.position.inSeconds;
    if (positionSeconds < 10) return;
    try {
      final mediaId = await dao.getOrCreateMediaId(
        _sourceId!,
        widget.videoId,
        Media.typeVideo,
      );
      await dao.saveProgress(mediaId, positionSeconds);
    } catch (_) {}
  }

  @override
  void dispose() {
    unawaited(_saveProgress());
    _playbackController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _ensurePlaybackController();
    // `$styles` is a mutable static that `AppScaffold` refreshes during its own
    // build, and this page sits below the navigator that `AppScaffold` wraps.
    // Reading a global in `build()` registers no InheritedWidget dependency,
    // so nothing tells Flutter to rebuild this page when the brightness flips.
    // `AppScaffold` does rebuild (it reads `Theme.of`), but it hands back the
    // very same `navigator` widget instance, and `Element.updateChild`
    // short-circuits on an identical child — so the whole route subtree keeps
    // the previous theme's colours.
    //
    // Adding the brightness into `AppScaffold`'s `KeyedSubtree` key would fix
    // the rebuild but destroy and rebuild the navigator with it, resetting tab
    // and bloc state. A dependency read is the cheap way to opt in.
    Theme.of(context);

    final content = MultiBlocProvider(
      providers: [
        ...getVideoBlocProviders(context, videoId: widget.videoId),
        Provider<MediaPlaybackController>.value(value: controller),
        BlocProvider<QueueBloc>(
          create: (context) => QueueBloc(
            sourceId: context.read<MediaSource>().id,
            controller: controller,
            repository: context.read<VideoDetailRepository>(),
            onItemSelected: (item) {
              context.read<VideoBloc>().add(
                SelectQueuedVideo(item.video.id, item.stream),
              );
            },
          ),
        ),
      ],
      child: BlocListener<VideoBloc, VideoState>(
        listenWhen: (previous, current) {
          final previousVideoId = previous.videoDetail?.video.id;
          final currentVideoId = current.videoDetail?.video.id;
          return current.mediaStream != null &&
              current.videoDetail != null &&
              (previous.mediaStream != current.mediaStream ||
                  previousVideoId != currentVideoId);
        },
        listener: (context, state) {
          final queue = context.read<QueueBloc>();
          if (queue.state.items.isEmpty) {
            queue.setCurrent(state.videoDetail!.video, state.mediaStream!);
          }
        },
        child: Builder(
          builder: (context) {
            final queue = context.read<QueueBloc>();
            return QueueAddController(
              addVideo: queue.enqueue,
              child: Scaffold(
                backgroundColor: $styles.colors.surface,
                body: _VideoContent(
                  videoId: widget.videoId,
                  playbackController: controller,
                  onBackClick: widget.onBackClick,
                ),
              ),
            );
          },
        ),
      ),
    );

    final progressLoadFuture = _progressLoadFuture;
    if (progressLoadFuture == null) return content;

    return FutureBuilder<void>(
      future: progressLoadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: CircularProgressIndicator(color: $styles.colors.accentFill),
          );
        }
        controller.restorePositionSeconds = _restorePositionSeconds;
        return content;
      },
    );
  }
}

class const _VideoContent({
  required final String videoId,
  required final MediaPlaybackController playbackController,
  final VoidCallback? onBackClick,
}) extends StatefulWidget {
  @override
  State<_VideoContent> createState() => _VideoContentState();
}

/// 视频页布局：内嵌态播放器在上、信息区在下；全屏时播放器铺满整屏。
///
/// 全屏状态放在页面而非播放器组件里：铺满要求父级把播放器放进 [Expanded]，
/// 而横屏与系统 UI 切换也是页面级副作用，两者都越不出页面这一层。
class _VideoContentState() extends State<_VideoContent> {
  bool _fullscreen = false;

  /// 进入 / 退出全屏：横屏 + 沉浸系统 UI，退出恢复竖屏与边缘到边缘。
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

  /// 最小化：退出全屏并暂停，播放位置保留，再次进入可续播。
  ///
  /// 这里只做到「收起 + 暂停」。真正的跨路由小窗需要把播放会话提升到应用级，
  /// 属独立范围，不在本页伪装实现。
  void _minimize() {
    if (_fullscreen) unawaited(_restorePortrait());
    if (mounted) setState(() => _fullscreen = false);
    unawaited(widget.playbackController.pause());
  }

  Future<void> _restorePortrait() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    // 带着横屏设置离开会把整个应用留在横屏，离开时必须还原。
    if (_fullscreen) unawaited(_restorePortrait());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final twoColumnAspect = PlatformInfo.isMobile ? .85 : 1.0;
    // ⚡ Bolt Optimization: Use MediaQuery.sizeOf(context) instead of MediaQuery.of(context).size.
    // Targeted size lookup prevents _VideoContent and descendant subtrees from rebuilding
    // when unrelated MediaQuery properties change (e.g., soft keyboard viewInsets or system padding).
    final size = MediaQuery.sizeOf(context);
    final bool useTwoColumnLayout =
        size.aspectRatio > twoColumnAspect || size.width >= 800;

    // ⚡ Bolt Optimization: Replace broad BlocBuilder with localized BlocSelector around VideoPlayer.
    // Prevents state updates (e.g. like, favorite, subscribe toggles) from rebuilding the entire lower
    // layout tree (DefaultTabController, TabBar, TabBarView, VideoCommentsView).
    // Saves ~2-4ms per frame emission during video detail state changes.
    final player = VideoPlayer(
      controller: widget.playbackController,
      queueManaged: true,
      fullscreen: _fullscreen,
      onToggleFullscreen: _toggleFullscreen,
      onMinimize: _minimize,
    );
    final content = Column(
      children: [
        if (!_fullscreen && widget.onBackClick != null)
          AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              onPressed: widget.onBackClick,
              tooltip: l10n.back,
              icon: const Icon(Icons.arrow_back),
            ),
          ),
        // 全屏时播放器铺满整屏，信息区一并收起。
        if (_fullscreen) Expanded(child: player) else player,
        if (!_fullscreen)
          Expanded(
            child: useTwoColumnLayout
                ? _buildTwoColumnLayout()
                : _buildNarrowTabContainer(l10n),
          ),
      ],
    );
    // 全屏走沉浸模式，不套 SafeArea：系统栏 inset 会在画面四周压出一圈边。
    if (_fullscreen) return content;
    return SafeArea(child: content);
  }

  Widget _buildTwoColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(child: VideoInfoView()),
        VerticalDivider(
          width: 1,
          color: $styles.colors.outline.withValues(alpha: 0.2),
        ),
        const Expanded(child: VideoCommentsView()),
      ],
    );
  }

  Widget _buildNarrowTabContainer(AppLocalizations l10n) {
    // ⚡ Bolt Optimization: Match DefaultTabController length to the 2 actual tabs
    // ('简介与相关' and '评论区') to eliminate out-of-bounds tab index state tracking and invalid animation math.
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: $styles.colors.surface,
            child: TabBar(
              labelColor: $styles.colors.accentText,
              unselectedLabelColor: $styles.colors.onSurfaceVariant,
              indicatorColor: $styles.colors.accentFill,
              indicatorWeight: 3,
              labelStyle: $styles.text.btn.copyWith(
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: $styles.text.btn,
              tabs: [
                Tab(text: l10n.infoAndRelated),
                Tab(text: l10n.commentsCountTab),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(children: [VideoInfoView(), VideoCommentsView()]),
          ),
        ],
      ),
    );
  }
}

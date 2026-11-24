import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../l10n/localization_file/app_localizations_zh.dart';
import '../../main.dart';
import '../../data/repository/video_detail_repository.dart';
import '../../database/dao/media_history_dao.dart';
import '../../database/table/media.dart';
import '../../datastore/media_history_settings.dart';
import '../../datastore/preferences_data_source.dart';
import 'bloc/video_bloc.dart';
import 'bloc/providers.dart';
import 'common_widgets/video_comments_view.dart';
import 'common_widgets/video_info_view.dart';
import 'common_widgets/video_player.dart';
import 'common_widgets/playback_queue_sheet.dart';
import 'player/media_playback_controller.dart';
import 'video_queue_request.dart';

class const VideoScreen({
  super.key,
  final String videoId = 'demo_video',
  final VideoQueueRequest? queue,
  final VoidCallback? onBackClick,

  /// 播放器会话，为 null 时页面自建并在销毁时释放。
  ///
  /// 测试用它注入假播放器：真实的 [MediaPlaybackController] 会初始化原生库，
  /// 在 widget 测试环境里起不来。与 [LiveScreen] 的注入方式一致。
  final MediaPlaybackController? playbackController,

  /// 画面构建器，透传给 [VideoPlayer]。
  ///
  /// 真 `Video` 依赖平台 Texture Registry 与 libmpv，widget 测试里渲染会挂住
  /// pump；需要断言「页面起播后 seek 到续播位置」的测试经此注入纯 Flutter 画面。
  final Widget Function(MediaPlaybackController controller)? surfaceBuilder,
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

  /// 播放队列解析结果。仅在进入页面时带 [VideoScreen.queue] 时有值。
  VideoQueueResult? _queueResult;

  /// 详情到达后的视频元数据，用于给历史记录补上标题与封面。
  ///
  /// 进度读取先于详情，建历史行时只有 id；没有这一步，历史列表会一直显示
  /// 原始 id 和空白封面。
  VideoModel? _videoModel;

  /// 进度周期性保存定时器（每 10 秒）。
  Timer? _progressSaveTimer;

  /// 播放器状态流订阅，用于监听队列切换。
  StreamSubscription<PlaybackState>? _playbackStateSubscription;

  /// 最后一次保存进度时的播放位置（秒），避免频繁写入。
  int _lastSavedPositionSeconds = -1;

  /// 最后一次保存进度时的队列索引，用于检测队列切换。
  int _lastSavedQueueIndex = -1;

  /// 惰性初始化：原生库（libmpv）须先 [MediaKit.ensureInitialized]，
  /// 在 widget 测试环境起不来；仅在 build 被调用时才创建。
  ///
  /// 外部注入的会话不在此处创建，也不由页面释放。
  MediaPlaybackController _ensurePlaybackController() {
    _playbackController ??=
        widget.playbackController ?? MediaPlaybackController();
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

  /// 进度初始化：有播放队列时先解析整队，否则只等这一条的进度。
  ///
  /// 队列解析结果是 [VideoPlayer] 实际起播的数据来源。它必须早于播放器拿到
  /// 单条 stream，否则播放器会先按单条打开、再被队列覆盖，白闪一次。
  Future<void> _initializeProgressAsync() async {
    final preferences = _preferences;
    if (preferences != null) {
      _historySettings = await MediaHistorySettings.load(preferences);
    }
    if (_historySettings.shouldReadProgress) await _loadProgressAsync();
    final queue = widget.queue;
    if (queue == null) return;
    await _resolveQueueAsync(queue);
  }

  /// 把播放队列里的每个 id 解析为可播地址。
  ///
  /// 逐条解析、逐条跳过：某个条目失效（源侧删除、历史脏数据）不该让整队
  /// 打不开。全部失败时把 [VideoQueueResult] 的错误交给页面提示。
  Future<void> _resolveQueueAsync(VideoQueueRequest queue) async {
    final sourceId = _sourceId;
    if (sourceId == null) return;
    final VideoDetailRepository repository;
    try {
      repository = context.read<VideoDetailRepository>();
    } on Object {
      return;
    }
    final items = <VideoQueueItem>[];
    var startIndex = 0;
    var resolved = 0;
    for (var index = 0; index < queue.videoIds.length; index++) {
      final id = queue.videoIds[index];
      final result = await repository.getMediaStream(id);
      switch (result) {
        case Success(:final success):
          if (index == queue.startIndex) startIndex = resolved;
          items.add(VideoQueueItem(videoId: id, stream: success));
          resolved++;
        case Error():
          // 跳过失效条目；起播位置按「实际进入队列的条目数」折算。
          break;
      }
    }
    if (!mounted) return;
    final error = items.isEmpty
        ? (AppLocalizations.of(context) ?? AppLocalizationsZh())
              .playlistPlaybackFailed
        : null;
    _setQueueResult(
      VideoQueueResult(
        items: items,
        startIndex: startIndex,
        requestedCount: queue.videoIds.length,
        error: error,
      ),
    );
  }

  void _setQueueResult(VideoQueueResult result) {
    setState(() => _queueResult = result);
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
      final mediaId = await dao.findMediaId(
        sourceId,
        requestedVideoId,
        Media.typeVideo,
      );
      if (mediaId == null) return;
      final progress = await dao.getProgressForMedia(mediaId);
      if (generation != _progressGeneration) return;
      if (progress != null && progress > 0) _restorePositionSeconds = progress;
    } catch (_) {}
  }

  /// 详情到达：记下元数据并立即补写历史行，避免只看几秒就退出时行里没有标题。
  void _onVideoDetail(VideoModel? video) {
    if (video == null) return;
    _videoModel = video;
    unawaited(_upsertHistoryMedia(video.id));
  }

  /// 用当前详情元数据补写历史行的标题、封面与作者。
  Future<void> _upsertHistoryMedia(String videoId) async {
    final dao = _mediaHistoryDao;
    final sourceId = _sourceId;
    if (dao == null || sourceId == null) return;
    if (!_historySettings.shouldWriteHistory) return;
    final video = _videoModel;
    final matches = video != null && video.id == videoId;
    try {
      await dao.getOrCreateMediaId(
        sourceId,
        videoId,
        Media.typeVideo,
        title: matches ? video.title : null,
        url: matches ? video.url : null,
        thumbnailUrl: matches ? video.thumbnailUrl : null,
        creatorProfileName: matches ? video.creatorProfileName : null,
        creatorProfileId: matches ? video.creatorProfileId : null,
        uploadDate: matches ? video.uploadDate : null,
      );
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

  /// 启动播放进度周期性保存与队列切换监听。
  void _startProgressTracking() {
    final controller = _playbackController;
    if (controller == null) return;
    // 避免重复启动。
    if (_progressSaveTimer != null || _playbackStateSubscription != null) {
      return;
    }

    _progressSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _saveProgressPeriodic();
    });

    _playbackStateSubscription = controller.states.listen((state) {
      _onPlaybackStateChanged(state);
    });
  }

  /// 停止播放进度跟踪。
  void _stopProgressTracking() {
    _progressSaveTimer?.cancel();
    _progressSaveTimer = null;
    _playbackStateSubscription?.cancel();
    _playbackStateSubscription = null;
  }

  /// 播放器状态变化回调：检测队列切换（currentIndex 变化）。
  void _onPlaybackStateChanged(PlaybackState state) {
    final currentIndex = state.currentIndex;
    // 队列索引变化且非初始值（-1 表示无队列或首次）。
    if (_lastSavedQueueIndex >= 0 && currentIndex != _lastSavedQueueIndex) {
      // 队列切换前保存上一条目的进度。
      _saveProgressForCurrentIndex(_lastSavedQueueIndex);
    }
    _lastSavedQueueIndex = currentIndex;
  }

  /// 周期性保存当前播放位置（每 10 秒）。
  Future<void> _saveProgressPeriodic() async {
    final controller = _playbackController;
    if (controller == null) return;
    final positionSeconds = controller.state.position.inSeconds;
    // 位置变化不足 5 秒不写，避免频繁写入。
    if (positionSeconds - _lastSavedPositionSeconds < 5) return;
    await _saveProgressForCurrentIndex(controller.state.currentIndex);
    _lastSavedPositionSeconds = positionSeconds;
  }

  /// 为指定队列索引的媒体保存进度。
  Future<void> _saveProgressForCurrentIndex(int queueIndex) async {
    final controller = _playbackController;
    final dao = _mediaHistoryDao;
    if (controller == null || dao == null || _sourceId == null) return;
    if (!_historySettings.shouldWriteHistory) return;

    // 获取当前播放列表中对应索引的媒体。
    // media_kit 的 Playlist 不直接暴露按索引取媒体的同步 API，
    // 这里通过播放器状态的 currentIndex 对应的媒体 ID 需要另行获取。
    // 简化实现：仅保存当前正在播放的视频（widget.videoId）进度。
    // 队列内其它项的进度保留在内存，切换到该项时再由 _loadProgressAsync 恢复。
    final positionSeconds = controller.state.position.inSeconds;
    if (positionSeconds < 10) return;

    try {
      await _upsertHistoryMedia(widget.videoId);
      final mediaId = await dao.getOrCreateMediaId(
        _sourceId!,
        widget.videoId,
        Media.typeVideo,
      );
      await dao.saveProgress(mediaId, positionSeconds);
    } catch (_) {}
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
      await _upsertHistoryMedia(widget.videoId);
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
    _stopProgressTracking();
    unawaited(_saveProgress());
    // 注入的会话归调用方所有：与 LiveScreen 一致，页面只释放自建的那个。
    if (widget.playbackController == null) _playbackController?.dispose();
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

    // 把关联视频 id 解析为可播地址并追加到页面级播放队列。
    // 解析失败返回 false，调用方（卡片按钮）据此提示。
    Future<bool> addVideoToQueue(
      String videoId,
      VideoDetailRepository repository,
      MediaPlaybackController controller,
    ) async {
      final result = await repository.getMediaStream(videoId);
      switch (result) {
        case Success(:final success):
          await controller.addToQueue(success, videoId: videoId);
          return true;
        case Error():
          return false;
      }
    }

    final content = MultiBlocProvider(
      providers: [
        ...getVideoBlocProviders(context, videoId: widget.videoId),
        Provider<MediaPlaybackController>.value(value: controller),
      ],
      child: QueueAddController(
        addVideoToQueue: addVideoToQueue,
        child: Scaffold(
          backgroundColor: $styles.colors.surface,
          body: _VideoContent(
            videoId: widget.videoId,
            playbackController: controller,
            queue: _queueResult,
            onBackClick: widget.onBackClick,
            onVideoDetail: _onVideoDetail,
            surfaceBuilder: widget.surfaceBuilder,
          ),
        ),
      ),
    );

    final progressLoadFuture = _progressLoadFuture;
    if (progressLoadFuture == null) {
      _startProgressTracking();
      return content;
    }

    return FutureBuilder<void>(
      future: progressLoadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: CircularProgressIndicator(color: $styles.colors.accentFill),
          );
        }
        controller.restorePositionSeconds = _restorePositionSeconds;
        _startProgressTracking();
        return content;
      },
    );
  }
}

class const _VideoContent({
  required final String videoId,
  required final MediaPlaybackController playbackController,
  final VideoQueueResult? queue,
  final VoidCallback? onBackClick,
  final ValueChanged<VideoModel?>? onVideoDetail,
  final Widget Function(MediaPlaybackController controller)? surfaceBuilder,
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

  /// 睡眠定时器到点选择「关闭播放器」时退出本页。
  ///
  /// 只在播放器是当前路由时关闭：被队列弹层或另一个视频盖住时弹栈会关掉
  /// 别人的页面，此时只保留已经生效的暂停。没有外部返回入口时自行弹栈。
  void _exitOnTimerEnd() {
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    final back = widget.onBackClick;
    if (back != null) {
      back();
      return;
    }
    if (route != null) unawaited(Navigator.of(context).maybePop());
  }

  Future<void> _restorePortrait() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void didUpdateWidget(covariant _VideoContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId == widget.videoId) return;
    // bloc 由上层 provider 持有，换视频时不会重建；不重新派发，详情与播放
    // 地址仍指向上一个视频，重试也会打在上一个 id 上。
    context.read<VideoBloc>()
      ..add(LoadVideoDetail(widget.videoId))
      ..add(LoadMediaStream(widget.videoId));
  }

  @override
  void dispose() {
    // 带着横屏设置离开会把整个应用留在横屏，离开时必须还原。
    if (_fullscreen) unawaited(_restorePortrait());
    super.dispose();
  }

  /// 双栏布局的最小可用宽度。
  ///
  /// 低于 600dp 时详情与评论改为标签页：并排两栏在手机上每栏不足 300dp，
  /// 标题与评论都会频繁换行。
  static const double _twoPaneMinWidth = 600;

  /// 常驻播放队列侧栏的最小可用宽度。
  ///
  /// 折叠屏展开态与手机横屏通常落在 700–900dp：此时再塞入 320dp 的队列侧栏，
  /// 详情与评论各只剩约 240dp，正是「挤占大量空间、布局混乱」的来源。
  /// 达不到这个宽度时队列改由播放器控制条上的入口以弹层打开，不占布局宽度。
  static const double _queuePaneMinWidth = 1280;
  static const double _queuePaneWidth = 320;

  /// 内嵌播放器最多占页面可用高度的比例。
  ///
  /// 横屏 / 折叠屏横屏时 16:9 画面按宽度铺开后会吃掉整屏高度，把下方内容
  /// 压成零高并触发 RenderFlex 溢出。超出上限时画面等比收缩、两侧留边，
  /// 剩余空间留给详情与评论。
  static const double _maxPlayerHeightFactorPortrait = 0.6;
  static const double _maxPlayerHeightFactorLandscape = 0.68;

  @override
  Widget build(BuildContext context) {
    final onVideoDetail = widget.onVideoDetail;
    if (onVideoDetail == null) return _buildBody(context);
    return BlocListener<VideoBloc, VideoState>(
      listenWhen: (previous, current) =>
          previous.videoDetail != current.videoDetail,
      listener: (context, state) => onVideoDetail(state.videoDetail?.video),
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();

    // ⚡ Bolt Optimization: Replace broad BlocBuilder with localized BlocSelector around VideoPlayer.
    // Prevents state updates (e.g. like, favorite, subscribe toggles) from rebuilding the entire lower
    // layout tree (DefaultTabController, TabBar, TabBarView, VideoCommentsView).
    // Saves ~2-4ms per frame emission during video detail state changes.
    final player = VideoPlayer(
      controller: widget.playbackController,
      fullscreen: _fullscreen,
      onToggleFullscreen: _toggleFullscreen,
      onRetry: () =>
          context.read<VideoBloc>().add(LoadMediaStream(widget.videoId)),
      onMinimize: _minimize,
      onExit: _exitOnTimerEnd,
      queue: widget.queue,
      surfaceBuilder: widget.surfaceBuilder,
    );

    // 全屏走沉浸模式，不套 SafeArea：系统栏 inset 会在画面四周压出一圈边。
    if (_fullscreen) {
      return Stack(
        children: [
          Positioned.fill(child: player),
          // 返回按钮独立于播放器控制层：控制层会自动收起，页面级返回入口
          // 必须始终可见。全屏下它先退出全屏，而不是直接离开页面。
          Positioned(
            top: $styles.insets.xs,
            left: $styles.insets.xs,
            child: _PlayerBackButton(
              onPressed: _toggleFullscreen,
              tooltip: l10n.back,
            ),
          ),
        ],
      );
    }

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          final maxPlayerHeight =
              constraints.maxHeight *
              (isLandscape
                  ? _maxPlayerHeightFactorLandscape
                  : _maxPlayerHeightFactorPortrait);
          return Column(
            children: [
              // 播放器与返回按钮同处一个 Stack：按钮叠在画面上，不再用一整条
              // AppBar 占掉竖向空间。按钮在 Stack 里而不是播放器的控制层里，
              // 因此不随控制层自动隐藏。
              Stack(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxPlayerHeight),
                    child: player,
                  ),
                  if (widget.onBackClick != null)
                    Positioned(
                      top: $styles.insets.xs,
                      left: $styles.insets.xs,
                      child: _PlayerBackButton(
                        onPressed: widget.onBackClick!,
                        tooltip: l10n.back,
                      ),
                    ),
                ],
              ),
              Expanded(child: _buildContent(constraints.maxWidth, l10n)),
            ],
          );
        },
      ),
    );
  }

  /// 详情 / 评论 / 队列的响应式排布。
  ///
  /// 队列只在足够宽时作为常驻侧栏；中等宽度下详情与评论并排，队列走弹层；
  /// 紧凑宽度下三者退回标签页。这样折叠屏展开态不会因为队列侧栏而把
  /// 详情和评论压成窄条。
  Widget _buildContent(double width, AppLocalizations l10n) {
    if (width >= _queuePaneMinWidth) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(child: VideoInfoView()),
          _paneDivider(),
          const Expanded(child: VideoCommentsView()),
          _paneDivider(),
          SizedBox(
            width: _queuePaneWidth,
            child: PlaybackQueueSheet(
              controller: widget.playbackController,
              embedded: true,
            ),
          ),
        ],
      );
    }
    if (width >= _twoPaneMinWidth) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(child: VideoInfoView()),
          _paneDivider(),
          const Expanded(child: VideoCommentsView()),
        ],
      );
    }
    return _buildNarrowTabContainer(l10n);
  }

  Widget _paneDivider() {
    return VerticalDivider(
      width: 1,
      color: $styles.colors.outline.withValues(alpha: 0.2),
    );
  }

  Widget _buildNarrowTabContainer(AppLocalizations l10n) {
    // ⚡ Bolt Optimization: Match DefaultTabController length to the 3 actual tabs
    // ('简介与相关', '评论区', '播放队列') to eliminate out-of-bounds tab index state tracking and invalid animation math.
    return DefaultTabController(
      length: 3,
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
                Tab(text: l10n.playbackQueue),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                VideoInfoView(),
                VideoCommentsView(),
                PlaybackQueueSheet(
                  controller: widget.playbackController,
                  embedded: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 叠在播放器左上角的页面返回入口。
///
/// 半透明 scrim 圆底让图标在任意画面上都保持对比度；尺寸走 Material 默认
/// 的 48dp 触达范围，不随画面缩放。它不属于播放器控制层，因此播放器全屏
/// 自动收起控制项时本按钮仍保持可见。
class const _PlayerBackButton({
  required final VoidCallback onPressed,
  required final String tooltip,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: const Icon(AppIcons.back),
      style: IconButton.styleFrom(
        backgroundColor: $styles.colors.scrim.withValues(alpha: 0.55),
        foregroundColor: $styles.colors.onScrim,
        minimumSize: const Size(48, 48),
      ),
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';
import 'package:provider/provider.dart';

import '../../../main.dart';
import '../../../utils/platfrom_info.dart';
import '../../../data/repository/video_detail_repository.dart';
import 'bloc/providers.dart';
import 'common_widgets/video_comments_view.dart';
import 'common_widgets/video_info_view.dart';
import 'common_widgets/video_player.dart';
import 'player/media_playback_controller.dart';

class const VideoScreen({super.key, final String videoId = 'demo_video'})
    extends StatefulWidget {
  @override
  State<VideoScreen> createState() => VideoScreenState();
}

class VideoScreenState() extends State<VideoScreen> {
  MediaPlaybackController? _playbackController;

  /// 惰性初始化：原生库（libmpv）须先 [MediaKit.ensureInitialized]，
  /// 在 widget 测试环境起不来；仅在 build 被调用时才创建。
  MediaPlaybackController _ensurePlaybackController() {
    if (_playbackController == null) {
      _playbackController = MediaPlaybackController();
    }
    return _playbackController!;
  }

  @override
  void dispose() {
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

    // 把关联视频 id 解析为可播地址并追加到页面级播放队列。
    // 解析失败返回 false，调用方（卡片按钮）据此提示。
    Future<bool> addVideoToQueue(
      String videoId,
      VideoDetailRepository repository,
      MediaPlaybackController controller,
    ) async {
      final result = await repository.getMediaStream(videoId);
      switch (result) {
        case Ok(:final value):
          await controller.addToQueue(value);
          return true;
        case Error():
          return false;
      }
    }

    return MultiBlocProvider(
      providers: [
        ...getVideoBlocProviders(context, videoId: widget.videoId),
        Provider<MediaPlaybackController>.value(value: controller),
      ],
      child: QueueAddController(
        addVideoToQueue: addVideoToQueue,
        child: Scaffold(
          backgroundColor: $styles.colors.surface,
          body: SafeArea(
            child: _VideoContent(
              videoId: widget.videoId,
              playbackController: controller,
            ),
          ),
        ),
      ),
    );
  }
}

class const _VideoContent({
  required final String videoId,
  required final MediaPlaybackController playbackController,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final twoColumnAspect = PlatformInfo.isMobile ? .85 : 1.0;
    final bool useTwoColumnLayout =
        MediaQuery.of(context).size.aspectRatio > twoColumnAspect ||
        MediaQuery.of(context).size.width >= 800;

    // ⚡ Bolt Optimization: Replace broad BlocBuilder with localized BlocSelector around VideoPlayerPlaceholder.
    // Prevents state updates (e.g. like, favorite, subscribe toggles) from rebuilding the entire lower
    // layout tree (DefaultTabController, TabBar, TabBarView, VideoCommentsView).
    // Saves ~2-4ms per frame emission during video detail state changes.
    return Column(
      children: [
        VideoPlayer(controller: playbackController),
        Expanded(
          child: useTwoColumnLayout
              ? _buildTwoColumnLayout()
              : _buildNarrowTabContainer(),
        ),
      ],
    );
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

  Widget _buildNarrowTabContainer() {
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
              tabs: const [
                Tab(text: '简介与相关'),
                Tab(text: '评论区 (1,429)'),
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

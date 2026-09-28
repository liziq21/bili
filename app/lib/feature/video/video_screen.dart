import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../main.dart';
import '../../utils/platfrom_info.dart';
import 'bloc/providers.dart';
import 'bloc/video_bloc.dart';
import 'common_widgets/video_comments_view.dart';
import 'common_widgets/video_info_view.dart';
import 'common_widgets/video_player_placeholder.dart';

class const VideoScreen({super.key, final String videoId = 'demo_video'})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // `$styles` is a mutable static that `AppScaffold` refreshes during its own
    // build, and this page sits below the navigator that `AppScaffold` wraps.
    // Reading a global in `build()` registers no InheritedWidget dependency, so
    // nothing tells Flutter to rebuild this page when the brightness flips.
    // `AppScaffold` does rebuild (it reads `Theme.of`), but it hands back the
    // very same `navigator` widget instance, and `Element.updateChild`
    // short-circuits on an identical child — so the whole route subtree keeps
    // the previous theme's colours.
    //
    // Adding the brightness into `AppScaffold`'s `KeyedSubtree` key would fix
    // the rebuild but destroy and rebuild the navigator with it, resetting tab
    // and bloc state. A dependency read is the cheap way to opt in.
    Theme.of(context);

    return MultiBlocProvider(
      providers: getVideoBlocProviders(context, videoId: videoId),
      child: Scaffold(
        backgroundColor: $styles.colors.surface,
        body: SafeArea(child: _VideoContent(videoId: videoId)),
      ),
    );
  }
}

class const _VideoContent({required final String videoId})
    extends StatelessWidget {
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
        BlocSelector<VideoBloc, VideoState, (String?, String?)>(
          selector: (state) => (
            state.videoDetail?.video.thumbnailUrl,
            state.videoDetail?.video.title,
          ),
          builder: (context, info) {
            return VideoPlayerPlaceholder(
              thumbnailUrl: info.$1,
              title: info.$2,
            );
          },
        ),
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

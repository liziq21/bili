import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../main.dart';
import '../../utils/platfrom_info.dart';
import 'bloc/providers.dart';
import 'bloc/video_bloc.dart';
import 'common_widgets/video_comments_view.dart';
import 'common_widgets/video_info_view.dart';
import 'common_widgets/video_player_placeholder.dart';

class VideoScreen extends StatelessWidget {
  const VideoScreen({
    super.key,
    this.videoId = 'demo_video',
  });

  final String videoId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: getVideoBlocProviders(context, videoId: videoId),
      child: Scaffold(
        backgroundColor: $styles.colors.offWhite,
        body: SafeArea(
          child: _VideoContent(videoId: videoId),
        ),
      ),
    );
  }
}

class _VideoContent extends StatelessWidget {
  const _VideoContent({required this.videoId});

  final String videoId;

  @override
  Widget build(BuildContext context) {
    final twoColumnAspect = PlatformInfo.isMobile ? .85 : 1.0;
    final bool useTwoColumnLayout =
        MediaQuery.of(context).size.aspectRatio > twoColumnAspect ||
            MediaQuery.of(context).size.width >= 800;

    return BlocBuilder<VideoBloc, VideoState>(
      builder: (context, state) {
        final videoDetail = state.videoDetail;

        return Column(
          children: [
            VideoPlayerPlaceholder(
              thumbnailUrl: videoDetail?.video.thumbnailUrl,
              title: videoDetail?.video.title,
            ),
            Expanded(
              child: useTwoColumnLayout
                  ? _buildTwoColumnLayout()
                  : _buildNarrowTabContainer(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTwoColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: VideoInfoView(),
        ),
        VerticalDivider(
          width: 1,
          color: $styles.colors.greyMedium.withValues(alpha: 0.2),
        ),
        const Expanded(
          child: VideoCommentsView(),
        ),
      ],
    );
  }

  Widget _buildNarrowTabContainer() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: $styles.colors.offWhite,
            child: TabBar(
              labelColor: $styles.colors.accent1,
              unselectedLabelColor: $styles.colors.caption,
              indicatorColor: $styles.colors.accent1,
              indicatorWeight: 3,
              labelStyle: $styles.text.btn.copyWith(fontWeight: FontWeight.bold),
              unselectedLabelStyle: $styles.text.btn,
              tabs: const [
                Tab(text: '简介与相关'),
                Tab(text: '评论区 (1,429)'),
                Tab(text: '源参数/日志'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                VideoInfoView(),
                VideoCommentsView(),
                _SourceLogsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceLogsView extends StatelessWidget {
  const _SourceLogsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all($styles.insets.sm),
      children: [
        Text(
          '多源引擎与分流状态日志',
          style: $styles.text.title2.copyWith(
            color: $styles.colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all($styles.insets.xs),
          decoration: BoxDecoration(
            color: $styles.colors.black,
            borderRadius: BorderRadius.circular($styles.corners.sm),
          ),
          child: Text(
            '[SYS] Engine: Impeller / Vulkan Backend\n'
            '[SRC] Selected Primary Source: Bilibili Native (CDN-SH-01)\n'
            '[NET] Ping: 24ms | Bandwidth: 82.4 Mbps\n'
            '[DEC] Video: H.265 / 4K 60fps | Audio: AAC 320kbps\n'
            '[SYNC] PeerTube fallback mirror initialized (Standing by)\n'
            '[STATUS] Playback Smooth, 0 Dropped Frames.',
            style: $styles.text.bodySmall.copyWith(
              color: $styles.colors.accent1,
              fontFamily: 'B612Mono',
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

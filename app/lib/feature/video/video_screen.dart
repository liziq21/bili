import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: VideoInfoView(),
        ),
        VerticalDivider(width: 1),
        Expanded(
          child: VideoCommentsView(),
        ),
      ],
    );
  }

  Widget _buildNarrowTabContainer() {
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: '简介'),
              Tab(text: '评论'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                VideoInfoView(),
                VideoCommentsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

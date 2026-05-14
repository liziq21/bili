import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../data/model/video_info_base.dart';
import '../widget/video_card.dart';
import 'search_result_view_model.dart';

class VideoSearchResult extends StatelessWidget {
  const VideoSearchResult({super.key, required this.viewModel});

  final SearchResultViewModel<VideoInfoBase> viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PagingListener(
        controller: viewModel.pagingController,
        builder: (context, state, fetchNextPage) => RefreshIndicator(
          onRefresh: () =>
              Future.sync(() => viewModel.pagingController.refresh()),
          child: CustomScrollView(
            slivers: [
              PagedSliverList<int, VideoInfoBase>(
                state: state,
                fetchNextPage: fetchNextPage,
                builderDelegate: PagedChildBuilderDelegate(
                  itemBuilder: (_, videoInfoBase, _) => VideoCard(
                    videoInfoBase: videoInfoBase,
                    //onTap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

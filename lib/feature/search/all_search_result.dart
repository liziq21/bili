import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../data/model/video_info_base.dart';
import '../widget/video_card.dart';
import 'search_result_view_model.dart';

class AllSearchResult extends StatelessWidget {
  const AllSearchResult({super.key, required this.viewModel});

  final AllSearchResultViewModel viewModel;

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
              SliverToBoxAdapter(
                child: ListenableBuilder(
                  listenable: viewModel,
                  builder: (_, _) {
                    final creatorProfile = viewModel.creatorProfile;
                    return creatorProfile != null
                        ? Text(creatorProfile.name)
                        : const SizedBox.shrink();
                  },
                ),
              ),
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

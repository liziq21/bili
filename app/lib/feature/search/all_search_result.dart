import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../ui/video_card.dart';
import 'search_result_view_model.dart';

class AllSearchResult extends StatelessWidget {
  final AllSearchResultViewModel viewModel;

  const AllSearchResult({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
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
            state: viewModel.state,
            fetchNextPage: viewModel.fetchNextPage,
            builderDelegate: PagedChildBuilderDelegate(
              itemBuilder: (_, videoInfoBase, _) => VideoCard(
                videoInfoBase: videoInfoBase,
                //onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

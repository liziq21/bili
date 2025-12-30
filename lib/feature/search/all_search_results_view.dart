import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';

import '../../data/model/search/bili_user_search_result.dart';
import '../../data/model/search/video_info_base.dart';
import '../widget/video_card.dart';
import 'all_search_ruselts_view_model.dart';

class AllSearchRuseltsView extends StatelessWidget {
  const AllSearchRuseltsView({
    super.key,
    //required this.viewModel,
  });


  @override
  Widget build(BuildContext context) {
    final AllSearchRuseltsViewModel viewModel = context.read;
    return Scaffold(
      body: PagingListener(
      controller: viewModel.pagingController,
      builder: (context, state, fetchNextPage) => RefreshIndicator(
        onRefresh: () => Future.sync(
          () => viewModel.pagingController.refresh(),
        ),
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
                itemBuilder: (_, item, _) => VideoCard(
                  duration: item.duration,
                  pic: item.pic,
                  play: item.play,
                  senddate: item.senddate,
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
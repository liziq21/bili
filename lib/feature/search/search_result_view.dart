import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../data/repository/model/concrete_results/bili_user_search_result.dart';
import '../../data/repository/model/concrete_results/video_search_result.dart';
import 'video_card.dart';

class SearchRuseltView extends StatelessWidget {
  const SearchRuseltView({
    super.key,
    required this.viewModel,
  });

  final SearchRuseltViewModel viewModel;

  @override
  Widget build(BuildContext context) {
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
                  /*final biliUserSearchResult = viewModel.biliUserSearchResult;
                  return biliUserSearchResult != null
                    ? 
                    : const SizedBox.shrink();*/
                    return const SizedBox.shrink();
                },
            ),
            PagedSliverList<int, Photo>(
              state: state,
              fetchNextPage: fetchNextPage,
              builderDelegate: PagedChildBuilderDelegate(
                itemBuilder: (context, item, index) => VideoCard(
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
    );
  }
}
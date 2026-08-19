import 'package:flutter/material.dart';

import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../ui/search/creator_profile_item.dart';
import '../../ui/video_card.dart';
import 'app_search_anchor.dart';
import 'search_result.dart';
import 'bloc/search_result_bloc.dart';

class const SearchResultScreen({
  super.key,
  required String query,
  required final VoidCallback? onBackClick,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final videoResultView = _videoResultView(context);
    final creatorProfileResultView = _creatorProfileResultView(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                clipBehavior: .none,
                shape: const StadiumBorder(),
                scrolledUnderElevation: 0.0,
                titleSpacing: 0.0,
                //backgroundColor: Colors.transparent,
                floating: true,
                //pinned: true,
                snap: true,
                //centerTitle: false,
                title: Padding(
                  padding: const EdgeInsets.fromLTRB(0.0, 8.0, 16.0, 8.0),
                  child: AppSearchAnchor(onSearch: (String query) {}),
                ),
                bottom: TabBar(
                  isScrollable: true,
                  tabAlignment: .start,
                  tabs: [
                    if (videoResultView != null) Text('video'),
                    if (creatorProfileResultView != null)
                      Text('creatorProfile'),
                  ],
                ),
              ),
              /*SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 100.0,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 10,
                      itemBuilder: (BuildContext context, int index) {
                        return SizedBox(
                          width: 100.0,
                          child: Card(child: Center(child: Text('Card $index'))),
                        );
                      },
                    ),
                  ),
                ),
              ),*/
              SliverToBoxAdapter(
                child: TabBarView(
                  children: [?videoResultView, ?creatorProfileResultView],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _videoResultView(BuildContext context) {
    final bloc = context.read<SearchResultBloc<VideoInfoBase>?>();
    if (bloc == null) return null;
    return SearchResult<VideoInfoBase>(
      itemBuilder: (_, videoInfoBase, _) =>
          VideoCard(videoInfoBase: videoInfoBase),
    );
  }

  Widget? _creatorProfileResultView(BuildContext context) {
    final bloc = context.read<SearchResultBloc<CreatorProfile>?>();
    if (bloc == null) return null;
    return SearchResult<CreatorProfile>(
      itemBuilder: (_, creatorProfile, _) =>
          CreatorProfileItem(creatorProfile: creatorProfile),
    );
  }
}

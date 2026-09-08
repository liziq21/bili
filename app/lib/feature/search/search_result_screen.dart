import 'package:flutter/material.dart';

import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../ui/search/creator_profile_item.dart';
import '../../ui/video_card.dart';
import 'app_search_anchor.dart';
import 'search_result.dart';
import 'bloc/search_result_bloc.dart';

class SearchResultScreen extends StatelessWidget {
  const SearchResultScreen({
    super.key,
    required this.query,
    this.onBackClick,
  });

  final String query;
  final VoidCallback? onBackClick;

  @override
  Widget build(BuildContext context) {
    final Map<Widget, Widget> tabAndView = {
      const Tab(text: 'UP 主'): _creatorProfileResultView(context) ?? const SizedBox.shrink(),
      const Tab(text: '视频'): _videoResultView(context) ?? const SizedBox.shrink(),
    };

    return DefaultTabController(
      length: tabAndView.length,
      child: Scaffold(
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 8.0, 16.0, 8.0),
            child: AppSearchAnchor(onSearch: (String query) {}),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: tabAndView.keys.toList(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TabBarView(children: tabAndView.values.toList()),
        ),
      ),
    );
  }

  Widget? _videoResultView(BuildContext context) {
    final bloc = context.read<SearchResultBloc<VideoModel>?>();
    if (bloc == null) return null;
    return SearchResult<VideoModel>(
      maxCrossAxisExtent: 200.0,
      itemAspectRatio: 0.8,
      itemBuilder: (_, videoInfoBase, _) =>
          VideoCard(videoInfoBase: videoInfoBase),
    );
  }

  Widget? _creatorProfileResultView(BuildContext context) {
    final bloc = context.read<SearchResultBloc<CreatorProfile>?>();
    if (bloc == null) return null;
    return SearchResult<CreatorProfile>(
      maxCrossAxisExtent: 400.0,
      itemAspectRatio: 3.5,
      itemBuilder: (_, creatorProfile, _) =>
          CreatorProfileItem(creatorProfile: creatorProfile),
    );
  }
}

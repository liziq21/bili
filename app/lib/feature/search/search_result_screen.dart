import 'package:material_ui/material_ui.dart';

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
    final Map<Widget, Widget> tabAndView = {
      Tab(text: 'creatorProfile'): ?_creatorProfileResultView(context),
      Tab(text: 'video'): ?_videoResultView(context),
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
            tabAlignment: .start,
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

  // ⚡ Bolt Optimization: Static item builders provide stable function references to
  // PagedChildBuilderDelegate inside SearchResult<T>, preventing delegate identity mismatches
  // and avoiding unnecessary grid child rebuilds during parent rebuilds or tab switches.
  static Widget _buildVideoItem(
    BuildContext context,
    VideoModel videoInfoBase,
    int index,
  ) => VideoCard(videoInfoBase: videoInfoBase);

  static Widget _buildCreatorProfileItem(
    BuildContext context,
    CreatorProfile creatorProfile,
    int index,
  ) => CreatorProfileItem(creatorProfile: creatorProfile);

  Widget? _videoResultView(BuildContext context) {
    final bloc = context.read<SearchResultBloc<VideoModel>?>();
    if (bloc == null) return null;
    return const SearchResult<VideoModel>(
      maxCrossAxisExtent: 200.0,
      itemAspectRatio: 0.8,
      itemBuilder: _buildVideoItem,
    );
  }

  Widget? _creatorProfileResultView(BuildContext context) {
    final bloc = context.read<SearchResultBloc<CreatorProfile>?>();
    if (bloc == null) return null;
    return const SearchResult<CreatorProfile>(
      maxCrossAxisExtent: 400.0,
      itemAspectRatio: 3.5,
      itemBuilder: _buildCreatorProfileItem,
    );
  }
}

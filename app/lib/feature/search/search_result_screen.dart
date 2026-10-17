import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:data/data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/localization_file/app_localizations.dart';
import '../../routing/router.dart';
import '../../ui/search/creator_profile_item.dart';
import '../../ui/video_card.dart';
import 'app_search_anchor.dart';
import 'search_result.dart';
import 'bloc/search_result_bloc.dart';

class const SearchResultScreen({
  super.key,
  required final String query,
  required final VoidCallback? onBackClick,
  final String? source,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final creatorLabel = l10n.creatorTab;
    final videoLabel = l10n.videoTab;

    final Map<Widget, Widget> tabAndView = {
      Tab(text: creatorLabel): ?_creatorProfileResultView(context),
      Tab(text: videoLabel): ?_videoResultView(context),
    };
    return DefaultTabController(
      length: tabAndView.length,
      child: Scaffold(
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 8.0, 16.0, 8.0),
            child: AppSearchAnchor(
              onSearch: (newQuery) {
                if (newQuery.isNotEmpty && newQuery != query) {
                  context.navigateToSearchResult(newQuery, source: source);
                }
              },
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: tabAndView.keys.toList(),
            onTap: (_) => HapticFeedback.selectionClick(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TabBarView(children: tabAndView.values.toList()),
        ),
      ),
    );
  }

  Widget _buildVideoItem(
    BuildContext context,
    VideoModel videoInfoBase,
    int index,
  ) => VideoCard(
    videoInfoBase: videoInfoBase,
    onTap: () => context.navigateToVideo(videoInfoBase.id, source: source),
  );

  Widget _buildCreatorProfileItem(
    BuildContext context,
    CreatorProfile creatorProfile,
    int index,
  ) => CreatorProfileItem(
    creatorProfile: creatorProfile,
    onTap: () => context.navigateToSpace(creatorProfile.id, source: source),
  );

  Widget? _videoResultView(BuildContext context) {
    final bloc = context.read<SearchResultBloc<VideoModel>?>();
    if (bloc == null) return null;
    return SearchResult<VideoModel>(
      maxCrossAxisExtent: 200.0,
      itemAspectRatio: 0.8,
      itemBuilder: _buildVideoItem,
    );
  }

  Widget? _creatorProfileResultView(BuildContext context) {
    final bloc = context.read<SearchResultBloc<CreatorProfile>?>();
    if (bloc == null) return null;
    return SearchResult<CreatorProfile>(
      maxCrossAxisExtent: 400.0,
      itemAspectRatio: 3.5,
      itemBuilder: _buildCreatorProfileItem,
    );
  }
}

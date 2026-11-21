import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../datastore/preferences_data_source.dart';
import '../../design/design.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';
import '../../routing/navigation_callbacks.dart';
import '../../routing/router.dart';
import '../../ui/search/creator_profile_item.dart';
import '../../ui/video_card.dart';
import 'app_search_anchor.dart';
import 'bloc/search_result_bloc.dart';
import 'common_widgets/filter_bar.dart';
import 'common_widgets/sort_bar.dart';
import 'search_filter_preferences.dart';
import 'search_result.dart';
import 'search_result_type.dart';

class const SearchResultScreen({
  super.key,
  required final String query,
  final VoidCallback? onBackClick,
  final String? source,
  final VideoNavCallback? onVideo,
  final SpaceNavCallback? onSpace,
  final LiveNavCallback? onLive,
}) extends StatefulWidget {
  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState() extends State<SearchResultScreen> {
  PreferencesDataSource? _preferences;
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreOptions());
  }

  Future<void> _restoreOptions() async {
    try {
      _preferences = context.read<PreferencesDataSource>();
    } on Object catch (_) {
      // 测试或独立使用时没有偏好设置 provider，按默认筛选渲染即可。
    }

    final bloc = context.read<SearchResultBloc<VideoModel>?>();
    if (bloc != null) {
      final selection = await SearchFilterPreferences.load(
        preferences: _preferences,
        sourceId: widget.source,
        defaults: bloc.defaultFilters,
        sortOptions: bloc.defaultSortOptions,
      );
      if (selection !=
          SearchFilterSelection(
            filters: bloc.state.filters,
            sortOption: bloc.state.currentSort,
          )) {
        bloc.add(
          ApplySearchOptions(
            filters: selection.filters,
            sortOption: selection.sortOption,
          ),
        );
      }
    }

    if (mounted) setState(() => _restored = true);
  }

  Future<void> _applyVideoOptions(
    List<FilterGroup> filters,
    SortOption? sortOption,
  ) async {
    final bloc = context.read<SearchResultBloc<VideoModel>?>();
    bloc?.add(ApplySearchOptions(filters: filters, sortOption: sortOption));
    await SearchFilterPreferences.save(
      preferences: _preferences,
      sourceId: widget.source,
      filters: filters,
      sortOption: sortOption,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final backTooltip = l10n?.back ?? 'Back';

    final tabs = <Tab>[];
    final views = <Widget>[];
    if (context.read<SearchResultBloc<VideoModel>?>() != null) {
      tabs.add(Tab(text: SearchResultType.video.label(l10n)));
      views.add(_videoResultView(context));
    }
    if (context.read<SearchResultBloc<CreatorProfile>?>() != null) {
      tabs.add(Tab(text: SearchResultType.channel.label(l10n)));
      views.add(_creatorProfileResultView(context));
    }
    if (context.read<SearchResultBloc<LiveRoomModel>?>() != null) {
      tabs.add(Tab(text: SearchResultType.live.label(l10n)));
      views.add(_liveRoomResultView(context));
    }

    return DefaultTabController(
      length: tabs.isEmpty ? 1 : tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 8.0, 16.0, 8.0),
            child: AppSearchAnchor(
              initialQuery: widget.query,
              onSearch: (newQuery) {
                if (newQuery.isNotEmpty && newQuery != widget.query) {
                  context.defaultNavigateToSearchResult(newQuery);
                }
              },
            ),
          ),
          bottom: tabs.isEmpty
              ? null
              : TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: tabs,
                  onTap: (_) => HapticFeedback.selectionClick(),
                ),
          leading: widget.onBackClick != null
              ? IconButton(
                  icon: const Icon(AppIcons.back),
                  tooltip: backTooltip,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.onBackClick?.call();
                  },
                )
              : null,
        ),
        body: !_restored
            ? Center(
                child: CircularProgressIndicator(
                  color: $styles.colors.accentFill,
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: tabs.isEmpty
                    ? const SizedBox.shrink()
                    : TabBarView(children: views),
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
    onTap: () => widget.onVideo?.call(videoInfoBase.id),
  );

  Widget _buildCreatorProfileItem(
    BuildContext context,
    CreatorProfile creatorProfile,
    int index,
  ) => CreatorProfileItem(
    creatorProfile: creatorProfile,
    onTap: () => widget.onSpace?.call(creatorProfile.id),
  );

  Widget _buildLiveRoomItem(
    BuildContext context,
    LiveRoomModel liveRoom,
    int index,
  ) => _LiveRoomResultCard(
    liveRoom: liveRoom,
    onTap: widget.onLive == null
        ? null
        : () => widget.onLive!('${liveRoom.id}'),
  );

  Widget _videoResultView(BuildContext context) {
    final bloc = context.read<SearchResultBloc<VideoModel>>();
    return BlocBuilder<
      SearchResultBloc<VideoModel>,
      SearchResultState<VideoModel>
    >(
      builder: (context, state) => _ResultBody(
        toolbar: _toolbar(context, bloc, state),
        child: SearchResult<VideoModel>(
          maxCrossAxisExtent: 200.0,
          itemAspectRatio: 0.8,
          itemBuilder: _buildVideoItem,
        ),
      ),
    );
  }

  Widget _toolbar(
    BuildContext context,
    SearchResultBloc<VideoModel> bloc,
    SearchResultState<VideoModel> state,
  ) {
    if (state.filters.isEmpty && state.sortOption.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: $styles.insets.xs),
      child: Row(
        children: [
          if (state.sortOption.isNotEmpty)
            SortBar(
              sortOptions: state.sortOption,
              current: state.currentSort,
              onChanged: (sort) => unawaited(
                _applyVideoOptions(state.filters, sort ?? state.currentSort),
              ),
            ),
          const Spacer(),
          if (state.filters.isNotEmpty)
            FilterBar(
              filters: state.filters,
              defaults: bloc.defaultFilters,
              onChanged: (filters) =>
                  unawaited(_applyVideoOptions(filters, state.currentSort)),
            ),
        ],
      ),
    );
  }

  Widget _creatorProfileResultView(BuildContext context) {
    final bloc = context.read<SearchResultBloc<CreatorProfile>?>();
    if (bloc == null) return const SizedBox.shrink();
    return SearchResult<CreatorProfile>(
      maxCrossAxisExtent: 400.0,
      itemAspectRatio: 3.5,
      itemBuilder: _buildCreatorProfileItem,
    );
  }

  Widget _liveRoomResultView(BuildContext context) {
    final bloc = context.read<SearchResultBloc<LiveRoomModel>?>();
    if (bloc == null) return const SizedBox.shrink();
    return SearchResult<LiveRoomModel>(
      maxCrossAxisExtent: 280.0,
      itemAspectRatio: 0.9,
      itemBuilder: _buildLiveRoomItem,
    );
  }
}

class const _ResultBody({
  required final Widget toolbar,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      toolbar,
      Expanded(child: child),
    ],
  );
}

class const _LiveRoomResultCard({
  required final LiveRoomModel liveRoom,
  final VoidCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final streamerName =
        liveRoom.creatorProfileName ?? (l10n?.unknownStreamer ?? 'Unknown');
    final semanticLabel = <String?>[
      liveRoom.title,
      l10n?.streamerLabel(streamerName),
    ].whereType<String>().join(l10n?.commaSeparator ?? ',');

    return Material(
      elevation: 1.0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular($styles.corners.md),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Tooltip(
        message: liveRoom.title,
        child: Semantics(
          button: onTap != null,
          label: semanticLabel,
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onTap!();
                  },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: switch (liveRoom.thumbnailUrl) {
                    final String url when url.isNotEmpty => CachedNetworkImage(
                      imageUrl: url,
                      memCacheWidth: 320,
                      fit: BoxFit.cover,
                      errorBuilder: (context, url, error) => Container(
                        color: $styles.colors.surfaceContainerHighest,
                        child: Icon(
                          AppIcons.liveTv,
                          color: $styles.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    _ => Container(
                      color: $styles.colors.surfaceContainerHighest,
                      child: Icon(
                        AppIcons.liveTv,
                        color: $styles.colors.onSurfaceVariant,
                      ),
                    ),
                  },
                ),
                Padding(
                  padding: EdgeInsets.all($styles.insets.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        liveRoom.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: $styles.text.bodySmallBold.copyWith(
                          color: $styles.colors.onSurfaceStrong,
                        ),
                      ),
                      SizedBox(height: $styles.insets.xxs),
                      Text(
                        streamerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: $styles.text.bodySmall.copyWith(
                          color: $styles.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

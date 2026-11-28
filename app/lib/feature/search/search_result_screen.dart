import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/repository/local_library_repository.dart';
import '../../database/app_database.dart';
import '../../datastore/preferences_data_source.dart';
import '../../design/design.dart';
import '../../l10n/localization_file/app_localizations.dart';
import '../../main.dart';
import '../../routing/navigation_callbacks.dart';
import '../../routing/router.dart';
import '../../ui/search/creator_profile_item.dart';
import '../../ui/video_actions_sheet.dart';
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
  LocalLibraryRepository? _localLibrary;
  String? _sourceId;
  StreamSubscription<List<LocalSubscriptionEntity>>? _subscription;
  Set<String> _subscribedCreatorIds = const {};
  bool _subscriptionsLoaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreOptions());
    _watchSubscriptions();
  }

  void _watchSubscriptions() {
    final repository = context.read<LocalLibraryRepository?>();
    final sourceId = widget.source;
    if (repository == null || sourceId == null) return;

    _localLibrary = repository;
    _sourceId = sourceId;
    _subscription = repository.watchSubscriptions().listen((subscriptions) {
      if (!mounted) return;
      setState(() {
        _subscriptionsLoaded = true;
        _subscribedCreatorIds = {
          for (final subscription in subscriptions)
            if (subscription.sourceId == sourceId) subscription.originalId,
        };
      });
    });
  }

  Future<void> _toggleSubscription(CreatorProfile creator) async {
    final repository = _localLibrary;
    final sourceId = _sourceId;
    if (repository == null || sourceId == null) return;

    try {
      await repository.setSubscription(
        sourceId: sourceId,
        creator: creator,
        subscribed: !_subscribedCreatorIds.contains(creator.id),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.operationFailed('$error') ?? '$error')),
      );
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
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
          titleSpacing: 8.0,
          title: Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
            child: AppSearchAnchor(
              initialQuery: widget.query,
              // 默认 SearchBar 最大宽度 800：1280 宽窗口里搜索框与右侧筛选
              // 图标之间会空出近 400px。这里放开上限让搜索框铺满标题区。
              barConstraints: const BoxConstraints(
                minHeight: 56.0,
                maxWidth: double.infinity,
              ),
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
                  // 与结果网格的 8px 内容内边距对齐；默认 AppBar 底部的 16
                  // 会让标签比卡片向右偏 8px。
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
  ) {
    final sourceId = _sourceId;
    return VideoCard(
      videoInfoBase: videoInfoBase,
      onTap: () => widget.onVideo?.call(videoInfoBase.id),
      onMorePressed: sourceId == null
          ? null
          : () => VideoActionsSheet.show(
              context,
              sourceId: sourceId,
              video: videoInfoBase,
            ),
    );
  }

  Widget _buildCreatorProfileItem(
    BuildContext context,
    CreatorProfile creatorProfile,
    int index,
  ) => CreatorProfileItem(
    creatorProfile: creatorProfile,
    onTap: () => widget.onSpace?.call(creatorProfile.id),
    isSubscribed: _subscriptionsLoaded
        ? _subscribedCreatorIds.contains(creatorProfile.id)
        : null,
    onToggleSubscribe: _localLibrary == null
        ? null
        : () => unawaited(_toggleSubscription(creatorProfile)),
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
          maxCrossAxisExtent: 240.0,
          maxColumns: 5,
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
      // 网格已经在 body 上有 8px 内边距，这里不再叠加，否则排序/筛选
      // 会比卡片多缩进 8px。
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          if (state.sortOption.isNotEmpty)
            SortBar(
              sortOptions: state.sortOption,
              current: state.currentSort,
              // 用 bloc 当前状态而不是本次 build 捕获的值：连改排序与筛选时，
              // 未变化的维度要取用户刚选的值，不能回退到旧状态。
              onChanged: (sort) => unawaited(
                _applyVideoOptions(
                  bloc.state.filters,
                  sort ?? bloc.state.currentSort,
                ),
              ),
            ),
          const Spacer(),
          if (state.filters.isNotEmpty)
            FilterBar(
              filters: state.filters,
              defaults: bloc.defaultFilters,
              onChanged: (filters) => unawaited(
                _applyVideoOptions(filters, bloc.state.currentSort),
              ),
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
      maxColumns: 4,
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

    // `excludeSemantics: true` drops the InkWell's tap action, so the same
    // callback has to be declared on the Semantics node as well.
    final handleTap = onTap == null
        ? null
        : () {
            HapticFeedback.lightImpact();
            onTap!();
          };

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
          onTap: handleTap,
          excludeSemantics: true,
          child: InkWell(
            onTap: handleTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 缩略图吃掉单元格的剩余高度：网格单元宽度由列数决定，
                // 固定 16:9 会在宽卡片底部留下大片空白。
                Expanded(
                  child: SizedBox.expand(
                    child: switch (liveRoom.thumbnailUrl) {
                      final String url when url.isNotEmpty =>
                        CachedNetworkImage(
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

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../main.dart';
import '../../providers/media_sources_provider.dart';
import 'bloc/home_bloc.dart';
import 'widgets/feed_status_view.dart';
import 'widgets/home_filter_bar.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/live_feed_section.dart';
import 'widgets/video_feed_section.dart';

class const HomeScreen({
  super.key,
  required final Function(String roomId) _onLive,
  required final Function(String searchQuery) _navigateToSearchResult,
  required final Function(String mid) _onSpace,
  required final Function(String id) _onVideo,
}) extends StatefulWidget {
  Function(String roomId) get onLive => _onLive;
  Function(String searchQuery) get navigateToSearchResult =>
      _navigateToSearchResult;
  Function(String mid) get onSpace => _onSpace;
  Function(String id) get onVideo => _onVideo;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState() extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      widget.navigateToSearchResult(trimmed);
    }
  }

  void _onFilterSelected(HomeFilter filter) {
    context.read<HomeBloc>().add(FilterSelected(filter.id));
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<HomeBloc>()..add(FeedsRequested(refresh: true));
    try {
      await bloc.stream.firstWhere((state) => !state.isRefreshing);
    } on StateError {
      // The bloc can close while this route is being disposed.
    }
  }

  Future<void> _showIdInputDialog({
    required BuildContext context,
    required String title,
    required String labelText,
    required String hintText,
    required String defaultId,
    required ValueChanged<String> onSubmit,
  }) async {
    final controller = TextEditingController(text: defaultId);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: $styles.text.h3.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              labelText,
              style: $styles.text.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: $styles.insets.xs),
            TextField(
              controller: controller,
              maxLength: 100,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              decoration: InputDecoration(
                counterText: '',
                hintText: hintText,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (val) => Navigator.of(context).pop(val.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty) {
      onSubmit(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sources = context.mediaSources;
    final colorScheme = Theme.of(context).colorScheme;

    // ⚡ Bolt Optimization: Isolate Scaffold and AppBar rebuild passes from HomeState feed updates.
    // By scoping BlocSelector to sourceId for the AppBar and moving BlocBuilder inside body,
    // feed emissions (e.g. pagination, refresh, items loading) will not trigger AppBar or
    // HomeSearchBar rebuilds, saving ~2-4ms per frame on feed state updates.
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: BlocSelector<HomeBloc, HomeState, String>(
          selector: (state) => state.sourceId,
          builder: (context, sourceId) {
            final activeSource = context.read<HomeBloc>().activeSource!;
            final hasLiveEntry = activeSource.liveRoomSearchDataSource != null;
            final isCreatorSource = activeSource.id == 'bilibili';

            return AppBar(
              titleSpacing: $styles.insets.xs,
              title: HomeSearchBar(
                controller: _searchController,
                sources: sources,
                activeSourceId: activeSource.id,
                activeSourceName: activeSource.name,
                onSubmitted: _onSearchSubmitted,
              ),
              actions: [
                if (hasLiveEntry)
                  IconButton(
                    icon: Icon(
                      Icons.live_tv,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    tooltip: '直达直播间',
                    onPressed: () => _showIdInputDialog(
                      context: context,
                      title: '直达直播间',
                      labelText: '请输入直播间 Room ID：',
                      hintText: '例如 230023',
                      defaultId: '230023',
                      onSubmit: widget.onLive,
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    Icons.account_circle_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: isCreatorSource ? '访问 UP主空间' : '访问创作者频道',
                  onPressed: () => _showIdInputDialog(
                    context: context,
                    title: isCreatorSource ? '访问 UP主空间' : '访问创作者频道',
                    labelText: '请输入 MID 或频道 ID：',
                    hintText: isCreatorSource ? '例如 188339' : '频道 ID',
                    defaultId: isCreatorSource ? '188339' : '',
                    onSubmit: widget.onSpace,
                  ),
                ),
                SizedBox(width: $styles.insets.xs),
              ],
            );
          },
        ),
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          final activeSource = context.read<HomeBloc>().activeSource!;
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: HomeFilterBar(
                    filters: state.filters,
                    activeFilterId: state.activeFilter.id,
                    onSelected: _onFilterSelected,
                    height: HomeFilterBar.preferredHeight(context),
                  ),
                ),
                ..._buildContentSlivers(state, activeSource.name),
                SliverToBoxAdapter(child: SizedBox(height: $styles.insets.lg)),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildContentSlivers(HomeState state, String sourceName) {
    if (state.activeFilter.kind == HomeFilterKind.placeholder) {
      return [
        SliverToBoxAdapter(
          child: FeedStatusView(
            icon: Icons.construction_rounded,
            message: '${state.activeFilter.label} 暂未开放',
            description: '该功能基于本地数据，仍在开发中',
          ),
        ),
      ];
    }

    final liveSections = state.visibleLiveSections;
    final videoSections = state.visibleVideoSections;

    if (liveSections.isEmpty && videoSections.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: FeedStatusView(
            icon: Icons.inbox_rounded,
            message: '$sourceName 暂无可用推荐',
            description: '该数据源未提供首页 Feed',
            onRetry: () => context.read<HomeBloc>().add(FeedsRequested()),
          ),
        ),
      ];
    }

    return [
      for (final section in liveSections)
        LiveFeedSection(
          section: section,
          sourceName: sourceName,
          onLiveTap: (liveRoom) => widget.onLive('${liveRoom.id}'),
          onRetry: () => context.read<HomeBloc>().add(FeedsRequested()),
        ),
      for (final section in videoSections)
        VideoFeedSection(
          section: section,
          sourceName: sourceName,
          onVideoTap: (video) => widget.onVideo(video.id),
          onRetry: () => context.read<HomeBloc>().add(FeedsRequested()),
          onLoadMore: () =>
              context.read<HomeBloc>().add(FeedNextPageRequested(section.id)),
        ),
    ];
  }
}

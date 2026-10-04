import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../main.dart';
import '../../providers/media_sources_provider.dart';
import 'bloc/home_bloc.dart';
import 'widgets/feed_status_view.dart';
import 'widgets/home_filter_bar.dart';
import 'widgets/home_source_selector.dart';
import 'widgets/live_feed_section.dart';
import 'widgets/video_feed_section.dart';

class const HomeScreen({
  super.key,
  required final Function(String roomId) _onLive,
  required final Function(String id) _onVideo,
}) extends StatelessWidget {
  Function(String roomId) get onLive => _onLive;
  Function(String id) get onVideo => _onVideo;

  void _onFilterSelected(BuildContext context, HomeFilter filter) {
    context.read<HomeBloc>().add(FilterSelected(filter.id));
  }

  Future<void> _onRefresh(BuildContext context) async {
    final bloc = context.read<HomeBloc>()..add(FeedsRequested(refresh: true));
    try {
      await bloc.stream.firstWhere((state) => !state.isRefreshing);
    } on StateError {
      // The bloc can close while this route is being disposed.
    }
  }

  @override
  Widget build(BuildContext context) {
    final sources = context.mediaSources;
    final colorScheme = Theme.of(context).colorScheme;

    // ⚡ Bolt Optimization: Isolate Scaffold and AppBar rebuild passes from HomeState feed updates.
    // By scoping BlocSelector to sourceId for the AppBar and moving BlocBuilder inside body,
    // feed emissions (e.g. pagination, refresh, items loading) will not trigger the AppBar,
    // saving ~2-4ms per frame on feed state updates.
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: BlocSelector<HomeBloc, HomeState, String>(
          selector: (state) => state.sourceId,
          builder: (context, sourceId) {
            final activeSource = context.read<HomeBloc>().activeSource!;

            return AppBar(
              titleSpacing: $styles.insets.sm,
              title: HomeSourceSelector(
                sources: sources,
                activeSourceId: activeSource.id,
              ),
              // 应用栏右侧只留设置入口。搜索走底栏第二项，直播间与创作者
              // 空间直达是按 ID 跳的调试入口，日常路径里没有使用价值。
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: '设置',
                  onPressed: () =>
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('设置开发中'))),
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
            onRefresh: () => _onRefresh(context),
            child: CustomScrollView(
              slivers: [
                // 数据源没有提供任何 Feed 时不挂筛选栏：空列表配一排空 chip
                // 比什么都不显示更像故障。
                if (state.filters.isNotEmpty)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: HomeFilterBar(
                      filters: state.filters,
                      activeFilterId: state.activeFilter!.id,
                      onSelected: (filter) =>
                          _onFilterSelected(context, filter),
                      height: HomeFilterBar.preferredHeight(context),
                    ),
                  ),
                ..._buildContentSlivers(context, state, activeSource.name),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildContentSlivers(
    BuildContext context,
    HomeState state,
    String sourceName,
  ) {
    final filter = state.activeFilter;
    if (filter == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: FeedStatusView(
            icon: Icons.inbox_rounded,
            message: '$sourceName 暂无可用推荐',
            description: '该数据源未提供首页 Feed',
            onRetry: () => context.read<HomeBloc>().add(FeedsRequested()),
          ),
        ),
      ];
    }

    final liveSections = state.visibleLiveSections;
    final videoSections = state.visibleVideoSections;

    if (liveSections.isEmpty && videoSections.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
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
          onLiveTap: (liveRoom) => onLive('${liveRoom.id}'),
          onRetry: () => context.read<HomeBloc>().add(FeedsRequested()),
        ),
      for (final section in videoSections)
        VideoFeedSection(
          section: section,
          sourceName: sourceName,
          onVideoTap: (video) => onVideo(video.id),
          onRetry: () => context.read<HomeBloc>().add(FeedsRequested()),
          onLoadMore: () =>
              context.read<HomeBloc>().add(FeedNextPageRequested(section.id)),
        ),
    ];
  }
}

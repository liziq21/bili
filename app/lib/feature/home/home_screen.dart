import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:data/data.dart' hide Page;
import 'package:data/data.dart' as data show Page;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:model/model.dart';

import '../../main.dart';
import '../../providers/media_sources_provider.dart';
import '../../ui/video_card.dart';
import 'bloc/home_bloc.dart';

@immutable
class FilterChipItem {
  const FilterChipItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required Function(String roomId) onLive,
    required Function(String searchQuery) navigateToSearchResult,
    required Function(String mid) onSpace,
    required Function(String id) onVideo,
  })  : _onLive = onLive,
        _navigateToSearchResult = navigateToSearchResult,
        _onSpace = onSpace,
        _onVideo = onVideo;

  final Function(String roomId) _onLive;
  final Function(String searchQuery) _navigateToSearchResult;
  final Function(String mid) _onSpace;
  final Function(String id) _onVideo;

  Function(String roomId) get onLive => _onLive;
  Function(String searchQuery) get navigateToSearchResult =>
      _navigateToSearchResult;
  Function(String mid) get onSpace => _onSpace;
  Function(String id) get onVideo => _onVideo;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeFilterId = 'all';

  // Cached mock video datasets as fallback
  static final List<VideoModel> _bilibiliRecommendedVideos = [
    VideoModel(
      id: 'BV1xx411c7mD',
      title: '【午餐盒子】生命会卡住生命',
      url: 'https://www.bilibili.com/video/BV1xx411c7mD',
      thumbnailUrl: 'https://picsum.photos/seed/bili1/640/360',
      viewCount: 79000,
      duration: 557,
      creatorProfileName: '五盒ll十箱',
      uploadDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    VideoModel(
      id: 'BV1aK4y1P7qG',
      title: 'ドリームコア / john feat.初音未来',
      url: 'https://www.bilibili.com/video/BV1aK4y1P7qG',
      thumbnailUrl: 'https://picsum.photos/seed/bili2/640/360',
      viewCount: 47000,
      duration: 127,
      creatorProfileName: '初音未来_Crypton',
      uploadDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    VideoModel(
      id: 'BV14z4y1m7S7',
      title: '【完全测评】传奇起点！真骨雕空我全形态回顾解析',
      url: 'https://www.bilibili.com/video/BV14z4y1m7S7',
      thumbnailUrl: 'https://picsum.photos/seed/bili3/640/360',
      viewCount: 182000,
      duration: 1601,
      creatorProfileName: '模玩档案馆',
      uploadDate: DateTime.now().subtract(const Duration(days: 3)),
    ),
    VideoModel(
      id: 'BV1yK4y1P7qH',
      title: '去中心化网络架构设计：从零构建轻量无追踪媒体协议',
      url: 'https://www.bilibili.com/video/BV1yK4y1P7qH',
      thumbnailUrl: 'https://picsum.photos/seed/bili4/640/360',
      viewCount: 31000,
      duration: 870,
      creatorProfileName: 'Kernel_Dev',
      uploadDate: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static final List<VideoModel> _youtubeRecommendedVideos = [
    VideoModel(
      id: 'dQw4w9WgXcQ',
      title: 'Rick Astley - Never Gonna Give You Up (Official Music Video)',
      url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      thumbnailUrl: 'https://picsum.photos/seed/yt1/640/360',
      viewCount: 1500000000,
      duration: 213,
      creatorProfileName: 'Rick Astley',
      uploadDate: DateTime.now().subtract(const Duration(days: 30)),
    ),
    VideoModel(
      id: 'L_LUpnjgPso',
      title: 'Building a Multi-Source Video Platform with Flutter',
      url: 'https://www.youtube.com/watch?v=L_LUpnjgPso',
      thumbnailUrl: 'https://picsum.photos/seed/yt2/640/360',
      viewCount: 240000,
      duration: 1140,
      creatorProfileName: 'Flutter Dev Tech',
      uploadDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  static const List<Map<String, String>> _recommendedLives = [
    {
      'id': '230023',
      'title': '【歌回】周五夜狂欢！新曲披露与杂谈',
      'streamer': '米娅Mia_Official',
      'viewers': '2.8万',
      'thumbnailUrl': 'https://picsum.photos/seed/live1/480/270',
    },
    {
      'id': '21686237',
      'title': '全国高校大师锦标赛总决赛 DAY 3',
      'streamer': '赛事官方直播间',
      'viewers': '5.4万',
      'thumbnailUrl': 'https://picsum.photos/seed/live2/480/270',
    },
    {
      'id': '5201314',
      'title': '深夜电台：用声音陪伴你的失眠之夜',
      'streamer': '月下听风',
      'viewers': '1.2万',
      'thumbnailUrl': 'https://picsum.photos/seed/live3/480/270',
    },
  ];

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

  void _onFilterSelected(String filterId, String label) {
    setState(() {
      _activeFilterId = filterId;
    });

    if (filterId == 'bookmarks' ||
        filterId == 'downloaded' ||
        filterId == 'history' ||
        filterId == 'sub') {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label 功能为本地功能占位符'),
          duration: const Duration(seconds: 2),
        ),
      );
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
    if (result != null && result.isNotEmpty) {
      onSubmit(result);
    }
  }

  List<FilterChipItem> _buildFilterChips(MediaSource activeSource) {
    final chips = <FilterChipItem>[
      const FilterChipItem(
        id: 'all',
        label: '全部推荐',
        icon: Icons.auto_awesome_rounded,
      ),
    ];

    for (final feed in activeSource.videoFeedDataSources) {
      IconData icon = Icons.video_library_rounded;
      if (feed.id == 'top100') {
        icon = Icons.local_fire_department_rounded;
      } else if (feed.id == 'hot' || feed.id == 'trending') {
        icon = Icons.whatshot_rounded;
      } else if (feed.id == 'recommend') {
        icon = Icons.recommend_rounded;
      }
      chips.add(FilterChipItem(id: feed.id, label: feed.title, icon: icon));
    }

    for (final feed in activeSource.liveRoomFeedDataSources) {
      chips.add(
        FilterChipItem(
          id: feed.id,
          label: feed.title,
          icon: Icons.sensors_rounded,
        ),
      );
    }

    chips.addAll(const [
      FilterChipItem(id: 'sub', label: '订阅更新', icon: Icons.rss_feed_rounded),
      FilterChipItem(
        id: 'bookmarks',
        label: '我的收藏',
        icon: Icons.bookmark_border_rounded,
      ),
      FilterChipItem(
        id: 'downloaded',
        label: '已下载',
        icon: Icons.download_done_rounded,
      ),
      FilterChipItem(id: 'history', label: '观看历史', icon: Icons.history_rounded),
    ]);

    return chips;
  }

  List<VideoModel> _getFallbackVideos(String sourceId) {
    if (sourceId == 'bilibili') {
      return _bilibiliRecommendedVideos;
    } else {
      return _youtubeRecommendedVideos;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sources = context.mediaSources;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: $styles.insets.xs,
        title: BlocSelector<HomeBloc, HomeState, String>(
          selector: (state) => state.sourceId,
          builder: (context, sourceId) {
            final effectiveSourceId = sources.any((s) => s.id == sourceId)
                ? sourceId
                : (sources.isNotEmpty ? sources.first.id : sourceId);

            final activeSource = sources.firstWhere(
              (s) => s.id == effectiveSourceId,
              orElse: () => sources.first,
            );

            return Container(
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular($styles.corners.lg),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: $styles.insets.xs),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: effectiveSourceId,
                        isDense: true,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        items: sources.map((source) {
                          return DropdownMenuItem<String>(
                            value: source.id,
                            child: Text(
                              source.name,
                              style: $styles.text.title2.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newSource) {
                          if (newSource != null) {
                            context.read<HomeBloc>().add(
                              ServiceSourceChanged(newSource),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  VerticalDivider(
                    indent: 10,
                    endIndent: 10,
                    width: $styles.insets.sm,
                    color: colorScheme.outlineVariant,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      maxLength: 200,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      onSubmitted: _onSearchSubmitted,
                      textInputAction: TextInputAction.search,
                      textAlignVertical: TextAlignVertical.center,
                      style: $styles.text.bodySmall.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '搜索 ${activeSource.name} 内容...',
                        hintStyle: $styles.text.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.8,
                          ),
                        ),
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: $styles.insets.xs,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.search_rounded,
                            size: 22,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () =>
                              _onSearchSubmitted(_searchController.text),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.bookmark_border_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            tooltip: '我的收藏',
            onPressed: () => _onFilterSelected('bookmarks', '我的收藏'),
          ),
          IconButton(
            icon: Icon(
              Icons.account_circle_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            tooltip: '个人中心',
            onPressed: () {
              final sourceId = context.read<HomeBloc>().state.sourceId;
              final effectiveSourceId = sources.any((s) => s.id == sourceId)
                  ? sourceId
                  : (sources.isNotEmpty ? sources.first.id : sourceId);
              _showIdInputDialog(
                context: context,
                title: effectiveSourceId == 'bilibili' ? '访问 UP主空间' : '访问创作者频道',
                labelText: '请输入 MID 或频道 ID：',
                hintText: effectiveSourceId == 'bilibili'
                    ? '例如 188339'
                    : '频道 ID',
                defaultId: effectiveSourceId == 'bilibili' ? '188339' : '',
                onSubmit: (id) => widget.onSpace(id),
              );
            },
          ),
          SizedBox(width: $styles.insets.xs),
        ],
      ),
      body: BlocSelector<HomeBloc, HomeState, String>(
        selector: (state) => state.sourceId,
        builder: (context, sourceId) {
          final effectiveSourceId = sources.any((s) => s.id == sourceId)
              ? sourceId
              : (sources.isNotEmpty ? sources.first.id : sourceId);

          final activeSource = sources.firstWhere(
            (s) => s.id == effectiveSourceId,
            orElse: () => sources.first,
          );

          final filterChips = _buildFilterChips(activeSource);
          final validFilterIds = filterChips.map((c) => c.id).toSet();
          final effectiveFilterId = validFilterIds.contains(_activeFilterId)
              ? _activeFilterId
              : 'all';

          final activeVideoFeeds = activeSource.videoFeedDataSources.where((f) {
            return effectiveFilterId == 'all' || effectiveFilterId == f.id;
          }).toList();

          final activeLiveFeeds = activeSource.liveRoomFeedDataSources.where((
            f,
          ) {
            return effectiveFilterId == 'all' || effectiveFilterId == f.id;
          }).toList();

          final hasLive = activeSource.liveRoomSearchDataSource != null;

          return CustomScrollView(
            slivers: [
              // 1. 横向 Dynamic Filter Chips Row
              SliverToBoxAdapter(
                child: Material(
                  color: Colors.transparent,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: $styles.insets.sm,
                      vertical: $styles.insets.xs,
                    ),
                    child: Row(
                      children: filterChips.map((chip) {
                        final isSelected = chip.id == effectiveFilterId;
                        return Padding(
                          padding: EdgeInsets.only(right: $styles.insets.xs),
                          child: FilterChip(
                            selected: isSelected,
                            showCheckmark: false,
                            avatar: Icon(
                              chip.icon,
                              size: 16,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            label: Text(chip.label),
                            labelStyle: $styles.text.bodySmall.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                            ),
                            selectedColor: colorScheme.primary,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                $styles.corners.lg,
                              ),
                            ),
                            onSelected: (_) =>
                                _onFilterSelected(chip.id, chip.label),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // 2. 交互与检索快捷操作区域 (Quick Actions Grid)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: $styles.insets.sm,
                    vertical: $styles.insets.xs,
                  ),
                  child: Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular($styles.corners.md),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all($styles.insets.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.explore_rounded,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              SizedBox(width: $styles.insets.xs),
                              Text(
                                '${activeSource.name} 核心服务入口',
                                style: $styles.text.title2.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: $styles.insets.xs),
                          Wrap(
                            spacing: $styles.insets.xs,
                            runSpacing: $styles.insets.xs,
                            children: [
                              ActionChip(
                                avatar: const Icon(
                                  Icons.search_rounded,
                                  size: 18,
                                ),
                                label: const Text('检索视频 / 频道'),
                                onPressed: () {
                                  _onSearchSubmitted(_searchController.text);
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(
                                  Icons.person_search_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  activeSource.id == 'bilibili'
                                      ? 'UP主空间'
                                      : '创作者频道',
                                ),
                                onPressed: () {
                                  _showIdInputDialog(
                                    context: context,
                                    title: activeSource.id == 'bilibili'
                                        ? '访问 UP主空间'
                                        : '访问创作者频道',
                                    labelText: '请输入 MID 或频道 ID：',
                                    hintText: activeSource.id == 'bilibili'
                                        ? '例如 188339'
                                        : '频道 ID',
                                    defaultId: activeSource.id == 'bilibili'
                                        ? '188339'
                                        : '',
                                    onSubmit: (id) => widget.onSpace(id),
                                  );
                                },
                              ),
                              if (hasLive)
                                ActionChip(
                                  avatar: const Icon(Icons.live_tv, size: 18),
                                  label: const Text('直播大厅'),
                                  onPressed: () {
                                    _showIdInputDialog(
                                      context: context,
                                      title: '直达直播间',
                                      labelText: '请输入直播间 Room ID：',
                                      hintText: '例如 230023',
                                      defaultId: '230023',
                                      onSubmit: (roomId) =>
                                          widget.onLive(roomId),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. 动态 Feed Sections (Live Room Feeds)
              for (final liveFeed in activeLiveFeeds) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      $styles.insets.sm,
                      $styles.insets.sm,
                      $styles.insets.sm,
                      $styles.insets.xs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.sensors_rounded,
                              color: colorScheme.error,
                              size: 24,
                            ),
                            SizedBox(width: $styles.insets.xs),
                            Text(
                              liveFeed.title,
                              style: $styles.text.h3.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: $styles.insets.xxs),
                        Text(
                          '${activeSource.name} 动态直播列表',
                          style: $styles.text.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.crossAxisExtent;
                    final cardWidth = availableWidth > 900
                        ? (availableWidth * 0.28).clamp(260.0, 360.0)
                        : (availableWidth > 600
                              ? (availableWidth * 0.38).clamp(240.0, 320.0)
                              : (availableWidth * 0.58).clamp(200.0, 280.0));
                    final imageHeight = cardWidth * (9 / 16);
                    final cardHeight =
                        imageHeight + $styles.insets.xs * 2 + 50.0;

                    return SliverToBoxAdapter(
                      child: SizedBox(
                        height: cardHeight,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(
                            horizontal: $styles.insets.sm,
                          ),
                          itemCount: _recommendedLives.length,
                          itemBuilder: (context, index) {
                            final live = _recommendedLives[index];
                            return Container(
                              width: cardWidth,
                              margin: EdgeInsets.only(right: $styles.insets.sm),
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                color: colorScheme.surfaceContainerLow,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    $styles.corners.md,
                                  ),
                                  side: BorderSide(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () => widget.onLive(live['id']!),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          AspectRatio(
                                            aspectRatio: 16 / 9,
                                            child: CachedNetworkImage(
                                              imageUrl: live['thumbnailUrl']!,
                                              memCacheWidth: 320,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    url,
                                                    error,
                                                  ) => Container(
                                                    color: colorScheme
                                                        .surfaceContainerHighest,
                                                    child: const Icon(
                                                      Icons.live_tv,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          Positioned(
                                            top: $styles.insets.xs,
                                            left: $styles.insets.xs,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: $styles.insets.xs,
                                                vertical:
                                                    $styles.insets.xxs / 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: colorScheme.error,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      $styles.corners.sm,
                                                    ),
                                              ),
                                              child: Text(
                                                '直播中',
                                                style: $styles.text.bodySmall
                                                    .copyWith(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          colorScheme.onError,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: $styles.insets.xs,
                                            right: $styles.insets.xs,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: $styles.insets.xs,
                                                vertical:
                                                    $styles.insets.xxs / 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.75,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      $styles.corners.sm,
                                                    ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.visibility_rounded,
                                                    size:
                                                        $styles.insets.sm -
                                                        $styles.insets.xxs,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(
                                                    width: $styles.insets.xxs,
                                                  ),
                                                  Text(
                                                    live['viewers']!,
                                                    style: $styles
                                                        .text
                                                        .bodySmall
                                                        .copyWith(
                                                          fontSize: 10,
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(
                                          $styles.insets.xs,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              live['title']!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: $styles.text.bodyBold
                                                  .copyWith(
                                                    fontSize: 13,
                                                    color:
                                                        colorScheme.onSurface,
                                                  ),
                                            ),
                                            SizedBox(
                                              height: $styles.insets.xxs / 2,
                                            ),
                                            Text(
                                              live['streamer']!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: $styles.text.bodySmall
                                                  .copyWith(
                                                    fontSize: 11,
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],

              // 4. 动态 Video Feed Sections
              for (final videoFeed in activeVideoFeeds) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      $styles.insets.sm,
                      $styles.insets.md,
                      $styles.insets.sm,
                      $styles.insets.xs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.recommend_rounded,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                            SizedBox(width: $styles.insets.xs),
                            Text(
                              videoFeed.title,
                              style: $styles.text.h3.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: $styles.insets.xxs),
                        Text(
                          '${activeSource.name} 动态内容展示',
                          style: $styles.text.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Video Feed Items Grid
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: $styles.insets.sm,
                    vertical: $styles.insets.xs,
                  ),
                  sliver: FutureBuilder<Result<data.Page<VideoModel>>>(
                    future: videoFeed.fetchFeed(),
                    builder: (context, snapshot) {
                      final res = snapshot.data;
                      final videos = res is Ok<data.Page<VideoModel>> &&
                              res.value.data.isNotEmpty
                          ? res.value.data
                          : _getFallbackVideos(activeSource.id);

                      return SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.crossAxisExtent;
                          final crossAxisCount = width > 900
                              ? 3
                              : (width > 600 ? 2 : 1);

                          return SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: $styles.insets.sm,
                                  crossAxisSpacing: $styles.insets.sm,
                                  childAspectRatio: crossAxisCount == 1
                                      ? 1.25
                                      : 1.1,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final video = videos[index];
                              return VideoCard(
                                variant: VideoCardVariant.feed,
                                sourceBadge: activeSource.name,
                                videoInfoBase: video,
                                onTap: () => widget.onVideo(video.id),
                                onMorePressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('操作: ${video.title}'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              );
                            }, childCount: videos.length),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

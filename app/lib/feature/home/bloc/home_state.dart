part of 'home_bloc.dart';

/// 主页筛选项类型
enum HomeFilterKind() {
  /// 单个视频 Feed
  videoFeed,

  /// 单个直播 Feed
  liveFeed,
}

/// 主页筛选项
@immutable
final class const HomeFilter({
  required final String id,
  required final String rawId,
  required final String label,
  required final HomeFilterKind kind,
  final String? configId,
}) extends Equatable {
  @override
  List<Object?> get props => [id, rawId, label, kind, configId];
}

@immutable
class const HomeState({
  required final String sourceId,
  required final HomeConfig homeConfig,
  final String? filterId,
  final bool isRefreshing = false,
  final List<FeedSectionState<VideoModel>> videoSections = const [],
  final List<FeedSectionState<LiveRoomModel>> liveSections = const [],
}) extends Equatable {
  static String videoFilterId(String feedId) => 'video:$feedId';

  static String liveFilterId(String feedId) => 'live:$feedId';

  /// 当前可用的筛选项：只列数据源真实提供的 Feed
  ///
  /// 本地功能（收藏 / 下载 / 订阅 / 历史）不作为筛选项出现：它们没有对应的
  /// 数据源实现，点开只能得到「暂未开放」。观看历史走底部导航的「我的」页，
  /// 收藏与下载在仓内连表都没有，等真有实现了再往这里加。
  List<HomeFilter> get filters {
    final sourceConfig = homeConfig.sources[sourceId];
    if (sourceConfig == null) return _defaultFilters;

    final remainingVideoSections = [...videoSections];
    final remainingLiveSections = [...liveSections];
    final List<({int index, HomeTabConfig tab})> configuredTabs =
        [
          for (var index = 0; index < sourceConfig.tabs.length; index++)
            (index: index, tab: sourceConfig.tabs[index]),
        ]..sort((a, b) {
          final order = a.tab.sortOrder.compareTo(b.tab.sortOrder);
          return order == 0 ? a.index.compareTo(b.index) : order;
        });

    final result = <HomeFilter>[];
    for (final configuredTab in configuredTabs) {
      final tab = configuredTab.tab;
      final videoIndex = _findSectionIndex(
        remainingVideoSections,
        tab,
        'video',
      );
      if (videoIndex != null) {
        final section = remainingVideoSections.removeAt(videoIndex);
        if (tab.isVisible) {
          result.add(
            HomeFilter(
              id: videoFilterId(section.id),
              rawId: section.id,
              label: tab.label,
              kind: HomeFilterKind.videoFeed,
              configId: tab.id,
            ),
          );
        }
        continue;
      }

      final liveIndex = _findSectionIndex(remainingLiveSections, tab, 'live');
      if (liveIndex == null) continue;

      final section = remainingLiveSections.removeAt(liveIndex);
      if (tab.isVisible) {
        result.add(
          HomeFilter(
            id: liveFilterId(section.id),
            rawId: section.id,
            label: tab.label,
            kind: HomeFilterKind.liveFeed,
            configId: tab.id,
          ),
        );
      }
    }
    return result;
  }

  List<HomeFilter> get _defaultFilters => [
    for (final section in videoSections)
      HomeFilter(
        id: videoFilterId(section.id),
        rawId: section.id,
        label: section.title,
        kind: HomeFilterKind.videoFeed,
      ),
    for (final section in liveSections)
      HomeFilter(
        id: liveFilterId(section.id),
        rawId: section.id,
        label: section.title,
        kind: HomeFilterKind.liveFeed,
      ),
  ];

  static int? _findSectionIndex<T>(
    List<FeedSectionState<T>> sections,
    HomeTabConfig tab,
    String kind,
  ) {
    final directIndex = sections.indexWhere((section) => section.id == tab.id);
    if (directIndex >= 0) return directIndex;

    final generatedIndex = sections.indexWhere(
      (section) => '${section.id}:$kind' == tab.id,
    );
    if (generatedIndex >= 0) return generatedIndex;
    return null;
  }

  /// 当前生效的筛选项
  ///
  /// [filterId] 可空且会在数据源切换后失效（各源的 Feed id 不同），此时回退到
  /// 首个可用 Feed。没有可用 Feed 时返回 null，由界面表达「该数据源未提供
  /// 首页 Feed」，不假装有第一项。
  HomeFilter? get activeFilter {
    final all = filters;
    if (all.isEmpty) return null;
    final id = filterId;
    if (id != null) {
      final selected = all.where((filter) => filter.id == id).firstOrNull;
      if (selected != null) return selected;
    }

    final mainTabId = homeConfig.sources[sourceId]?.mainTabId;
    if (mainTabId != null) {
      final main = all
          .where(
            (filter) => filter.id == mainTabId || filter.configId == mainTabId,
          )
          .firstOrNull;
      if (main != null) return main;
    }
    return all.first;
  }

  /// 当前筛选下应展示的视频区块
  ///
  /// 一次只展示一个 Feed：筛选项即 Feed 本身，不存在「一次看全部」的聚合态。
  List<FeedSectionState<VideoModel>> get visibleVideoSections {
    final filter = activeFilter;
    if (filter == null || filter.kind != HomeFilterKind.videoFeed) {
      return const [];
    }
    return [
      for (final section in videoSections)
        if (section.id == filter.rawId) section,
    ];
  }

  /// 当前筛选下应展示的直播区块
  List<FeedSectionState<LiveRoomModel>> get visibleLiveSections {
    final filter = activeFilter;
    if (filter == null || filter.kind != HomeFilterKind.liveFeed) {
      return const [];
    }
    return [
      for (final section in liveSections)
        if (section.id == filter.rawId) section,
    ];
  }

  /// [clearFilter] 把选中项复位成「跟随首个 Feed」
  ///
  /// 单独给一个开关而不是靠 `filterId ?? this.filterId`：[filterId] 本身可空，
  /// `??` 分不出「没传」和「传 null」，切换数据源时无法清掉旧源的选中项。
  HomeState copyWith({
    String? sourceId,
    HomeConfig? homeConfig,
    String? filterId,
    bool clearFilter = false,
    bool? isRefreshing,
    List<FeedSectionState<VideoModel>>? videoSections,
    List<FeedSectionState<LiveRoomModel>>? liveSections,
  }) {
    return HomeState(
      sourceId: sourceId ?? this.sourceId,
      homeConfig: homeConfig ?? this.homeConfig,
      filterId: clearFilter ? null : (filterId ?? this.filterId),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      videoSections: videoSections ?? this.videoSections,
      liveSections: liveSections ?? this.liveSections,
    );
  }

  @override
  List<Object?> get props => [
    sourceId,
    homeConfig,
    filterId,
    isRefreshing,
    videoSections,
    liveSections,
  ];
}

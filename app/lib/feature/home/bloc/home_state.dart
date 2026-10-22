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

    final usedTabIds = <String>{};
    final videoSectionsByTabId = _sectionMap(
      videoSections,
      kind: 'video',
      usedTabIds: usedTabIds,
    );
    final liveSectionsByTabId = _sectionMap(
      liveSections,
      kind: 'live',
      usedTabIds: usedTabIds,
    );
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
      final videoSection = videoSectionsByTabId.remove(tab.id);
      if (videoSection != null) {
        if (tab.isVisible) {
          result.add(
            HomeFilter(
              id: videoFilterId(videoSection.id),
              rawId: videoSection.id,
              label: tab.label,
              kind: HomeFilterKind.videoFeed,
              configId: tab.id,
            ),
          );
        }
        continue;
      }

      final liveSection = liveSectionsByTabId.remove(tab.id);
      if (liveSection == null) continue;

      if (tab.isVisible) {
        result.add(
          HomeFilter(
            id: liveFilterId(liveSection.id),
            rawId: liveSection.id,
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

  static Map<String, FeedSectionState<T>> _sectionMap<T>(
    List<FeedSectionState<T>> sections, {
    required String kind,
    required Set<String> usedTabIds,
  }) {
    final result = <String, FeedSectionState<T>>{};
    for (final section in sections) {
      var tabId = section.id;
      if (usedTabIds.contains(tabId)) {
        var suffix = 2;
        tabId = '${section.id}:$kind';
        while (usedTabIds.contains(tabId)) {
          tabId = '${section.id}:$kind$suffix';
          suffix++;
        }
      }
      usedTabIds.add(tabId);
      result[tabId] = section;
    }
    return result;
  }

  /// 当前生效的筛选项
  ///
  /// [filterId] 可空且会在数据源切换后失效（各源的 Feed id 不同），此时回退到
  /// 配置的主 tab，再回退到首个可见 Feed。没有可用 Feed 时返回 null，由界面
  /// 表达「该数据源未提供首页 Feed」，不假装有第一项。
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

  /// [clearFilter] 把选中项复位成「跟随配置的主 tab」
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

part of 'home_bloc.dart';

/// 主页筛选项类型
enum HomeFilterKind {
  /// 聚合展示全部 Feed
  all,

  /// 单个视频 Feed
  videoFeed,

  /// 单个直播 Feed
  liveFeed,

  /// 本地功能占位（收藏 / 历史 / 下载 / 订阅）
  placeholder,
}

/// 主页筛选项
@immutable
final class const HomeFilter({
  required final String id,
  required final String label,
  required final HomeFilterKind kind,
}) extends Equatable {
  @override
  List<Object?> get props => [id, label, kind];
}

@immutable
class HomeState extends Equatable {
  const HomeState({
    this.sourceId = 'bilibili',
    this.filterId = allFilterId,
    this.isRefreshing = false,
    this.videoSections = const [],
    this.liveSections = const [],
  });

  /// “全部推荐”聚合筛选项的标识
  static const String allFilterId = 'all';

  /// 本地功能占位筛选项
  static const List<HomeFilter> placeholderFilters = [
    HomeFilter(id: 'sub', label: '订阅更新', kind: HomeFilterKind.placeholder),
    HomeFilter(
      id: 'bookmarks',
      label: '我的收藏',
      kind: HomeFilterKind.placeholder,
    ),
    HomeFilter(
      id: 'downloaded',
      label: '已下载',
      kind: HomeFilterKind.placeholder,
    ),
    HomeFilter(id: 'history', label: '观看历史', kind: HomeFilterKind.placeholder),
  ];

  final String sourceId;
  final String filterId;
  final bool isRefreshing;
  final List<FeedSectionState<VideoModel>> videoSections;
  final List<FeedSectionState<LiveRoomModel>> liveSections;

  /// 当前可用的全部筛选项（聚合项 + 数据源 Feed + 本地占位项）
  List<HomeFilter> get filters => [
    const HomeFilter(id: allFilterId, label: '全部推荐', kind: HomeFilterKind.all),
    for (final section in videoSections)
      HomeFilter(
        id: section.id,
        label: section.title,
        kind: HomeFilterKind.videoFeed,
      ),
    for (final section in liveSections)
      HomeFilter(
        id: section.id,
        label: section.title,
        kind: HomeFilterKind.liveFeed,
      ),
    ...placeholderFilters,
  ];

  /// 当前生效的筛选项（筛选项随数据源变化失效时回退到聚合项）
  HomeFilter get activeFilter => filters.firstWhere(
    (filter) => filter.id == filterId,
    orElse: () => filters.first,
  );

  /// 当前筛选下应展示的视频区块
  List<FeedSectionState<VideoModel>> get visibleVideoSections =>
      switch (activeFilter.kind) {
        HomeFilterKind.all => videoSections,
        HomeFilterKind.videoFeed =>
          videoSections
              .where((section) => section.id == activeFilter.id)
              .toList(),
        HomeFilterKind.liveFeed || HomeFilterKind.placeholder => const [],
      };

  /// 当前筛选下应展示的直播区块
  List<FeedSectionState<LiveRoomModel>> get visibleLiveSections =>
      switch (activeFilter.kind) {
        HomeFilterKind.all => liveSections,
        HomeFilterKind.liveFeed =>
          liveSections
              .where((section) => section.id == activeFilter.id)
              .toList(),
        HomeFilterKind.videoFeed || HomeFilterKind.placeholder => const [],
      };

  HomeState copyWith({
    String? sourceId,
    String? filterId,
    bool? isRefreshing,
    List<FeedSectionState<VideoModel>>? videoSections,
    List<FeedSectionState<LiveRoomModel>>? liveSections,
  }) {
    return HomeState(
      sourceId: sourceId ?? this.sourceId,
      filterId: filterId ?? this.filterId,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      videoSections: videoSections ?? this.videoSections,
      liveSections: liveSections ?? this.liveSections,
    );
  }

  @override
  List<Object?> get props => [
    sourceId,
    filterId,
    isRefreshing,
    videoSections,
    liveSections,
  ];
}

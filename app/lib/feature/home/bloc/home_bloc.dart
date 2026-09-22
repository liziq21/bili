import 'dart:async';

import 'package:data/data.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:model/model.dart';

import '../../../data/repository/user_data/user_data_repository.dart';
import 'feed_section_state.dart';

export 'feed_section_state.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc({
  required final UserDataRepository userDataRepository,
  required final List<MediaSource> mediaSources,
}) extends Bloc<HomeEvent, HomeState> {
  this
    : _userDataRepository = userDataRepository,
      _mediaSources = mediaSources,
      super(const HomeState()) {
    on<MonitorUserData>(_onMonitorUserData);
    on<ServiceSourceChanged>(_onServiceSourceChanged);
    on<FeedsRequested>(_onFeedsRequested);
    on<FilterSelected>(_onFilterSelected);
    on<FeedNextPageRequested>(_onFeedNextPageRequested);

    add(MonitorUserData());
    add(FeedsRequested());
  }

  final UserDataRepository _userDataRepository;
  final List<MediaSource> _mediaSources;
  final _log = Logger('HomeBloc');

  /// 当前生效的数据源，`sourceId` 不可用时回退到首个可用数据源
  MediaSource? get activeSource {
    if (_mediaSources.isEmpty) return null;
    return _mediaSources.firstWhere(
      (source) => source.id == state.sourceId,
      orElse: () => _mediaSources.first,
    );
  }

  Future<void> _onMonitorUserData(
    MonitorUserData event,
    Emitter<HomeState> emit,
  ) async {
    await emit.forEach<UserData>(
      _userDataRepository.data,
      onData: (userData) {
        if (userData.sourceId == state.sourceId) return state;
        // 数据源切换后旧 Feed 不再适用，清空并重新拉取。
        add(FeedsRequested());
        return state.copyWith(
          sourceId: userData.sourceId,
          filterId: HomeState.allFilterId,
          videoSections: const [],
          liveSections: const [],
        );
      },
      onError: (error, stackTrace) {
        _log.warning('Failed to load user data in HomeBloc', error, stackTrace);
        return state;
      },
    );
  }

  Future<void> _onServiceSourceChanged(
    ServiceSourceChanged event,
    Emitter<HomeState> emit,
  ) async {
    if (event.sourceId == state.sourceId) return;
    _log.info('Changing service source to: ${event.sourceId}');
    await _userDataRepository.setSourceId(event.sourceId);
  }

  Future<void> _onFilterSelected(
    FilterSelected event,
    Emitter<HomeState> emit,
  ) async {
    if (event.filterId == state.filterId) return;
    emit(state.copyWith(filterId: event.filterId));
  }

  Future<void> _onFeedsRequested(
    FeedsRequested event,
    Emitter<HomeState> emit,
  ) async {
    final source = activeSource;
    if (source == null) return;

    final videoFeeds = source.videoFeedDataSources;
    final liveFeeds = source.liveRoomFeedDataSources;

    emit(
      state.copyWith(
        isRefreshing: event.refresh,
        videoSections: [
          for (final feed in videoFeeds)
            FeedSectionState<VideoModel>(
              id: feed.id,
              title: feed.title,
              status: FeedStatus.loading,
            ),
        ],
        liveSections: [
          for (final feed in liveFeeds)
            FeedSectionState<LiveRoomModel>(
              id: feed.id,
              title: feed.title,
              status: FeedStatus.loading,
            ),
        ],
      ),
    );

    await Future.wait([
      for (final feed in videoFeeds) _fetchVideoPage(feed, emit, pageKey: 1),
      for (final feed in liveFeeds) _fetchLivePage(feed, emit, pageKey: 1),
    ]);

    if (state.isRefreshing) emit(state.copyWith(isRefreshing: false));
  }

  Future<void> _onFeedNextPageRequested(
    FeedNextPageRequested event,
    Emitter<HomeState> emit,
  ) async {
    final source = activeSource;
    if (source == null) return;

    final section = state.videoSections
        .where((section) => section.id == event.feedId)
        .firstOrNull;
    if (section == null || !section.hasMore || section.isLoadingMore) return;

    final feed = source.videoFeedDataSources
        .where((feed) => feed.id == event.feedId)
        .firstOrNull;
    if (feed == null) return;

    emit(
      _replaceVideoSection(
        section.copyWith(status: FeedStatus.loadingMore, clearError: true),
      ),
    );
    await _fetchVideoPage(feed, emit, pageKey: section.pageKey + 1);
  }

  Future<void> _fetchVideoPage(
    VideoFeedRemoteDataSource feed,
    Emitter<HomeState> emit, {
    required int pageKey,
  }) async {
    final result = await feed.fetchFeed(pageKey: pageKey);
    final current = state.videoSections
        .where((section) => section.id == feed.id)
        .firstOrNull;
    if (current == null || emit.isDone) return;

    emit(_replaceVideoSection(_merge(current, result, pageKey: pageKey)));
  }

  Future<void> _fetchLivePage(
    LiveRoomFeedRemoteDataSource feed,
    Emitter<HomeState> emit, {
    required int pageKey,
  }) async {
    final result = await feed.fetchFeed(pageKey: pageKey);
    final current = state.liveSections
        .where((section) => section.id == feed.id)
        .firstOrNull;
    if (current == null || emit.isDone) return;

    emit(_replaceLiveSection(_merge(current, result, pageKey: pageKey)));
  }

  FeedSectionState<T> _merge<T>(
    FeedSectionState<T> section,
    Result<Page<T>> result, {
    required int pageKey,
  }) {
    return switch (result) {
      Ok(:final value) => section.copyWith(
        status: FeedStatus.success,
        items: pageKey <= 1 ? value.data : [...section.items, ...value.data],
        pageKey: pageKey,
        hasMore: pageKey < value.totalPages,
        clearError: true,
      ),
      Error(:final error) => () {
        _log.warning('Failed to load feed ${section.id}', error);
        return section.copyWith(status: FeedStatus.failure, error: error);
      }(),
    };
  }

  HomeState _replaceVideoSection(FeedSectionState<VideoModel> section) {
    return state.copyWith(
      videoSections: [
        for (final item in state.videoSections)
          if (item.id == section.id) section else item,
      ],
    );
  }

  HomeState _replaceLiveSection(FeedSectionState<LiveRoomModel> section) {
    return state.copyWith(
      liveSections: [
        for (final item in state.liveSections)
          if (item.id == section.id) section else item,
      ],
    );
  }
}

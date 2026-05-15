import 'dart:async';

import '../../../data/model/creator_profile.dart';
import '../../../data/model/live_room.dart';
import '../../../data/model/video_info_base.dart';
import '../../../data/repository/search_contents/search_contents_repository.dart';
import '../../../model/data/filter_group.dart';
import '../../../model/data/sort_option.dart';
import '../../../data/model/paged_result.dart';
import '../../../data/model/search_results.dart';
import '../../../utils/result.dart';
import '../../network/network_search_data_source.dart';
import '../model/search_results.dart';

class BilibiliAggregateSearchRepository extends VideoSearchRepository {
  const BilibiliAggregateSearchRepository({
    required NetworkSearchDataSource network,
  }) : _network = network;

  final NetworkSearchDataSource _network;

  @override
  Future<Result<AggregateSearchPage>> search(SearchQuery searchQuery) async {
    final result = await _network.searchAll(
      searchQuery.query,
      page: searchQuery.page,
    );
    return result.map((it) => it.asModel());
  }
}

class BilibiliUserSearchRepository extends CreatorProfileSearchRepository {
  const BilibiliUserSearchRepository({required NetworkSearchDataSource network})
    : _network = network;

  final NetworkSearchDataSource _network;
  @override
  Future<Result<Page<CreatorProfile>>> search(SearchQuery searchQuery) async {
    final result = await _network.searchBiliUser(
      searchQuery.query,
      page: searchQuery.page,
    );
    return result.map((it) => it.asPagedCreatorProfile());
  }
}

class BilibiliLiveRoomSearchRepository extends LiveRoomSearchRepository {
  const BilibiliLiveRoomSearchRepository({
    required NetworkSearchDataSource network,
  }) : _network = network;

  final NetworkSearchDataSource _network;

  @override
  Future<Result<Page<LiveRoom>>> search(SearchQuery searchQuery) async {
    final result = await _network.searchLiveRoom(
      searchQuery.query,
      page: searchQuery.page,
    );
    return result.map((it) => it.asPagedLiveRooms());
  }
}

class BilibiliVideoSearchRepository extends VideoSearchRepository {
  const BilibiliVideoSearchRepository({
    required NetworkSearchDataSource network,
  }) : _network = network;

  final NetworkSearchDataSource _network;

  @override
  Future<Result<Page<VideoInfoBase>>> search(SearchQuery searchQuery) async {
    final result = await _network.searchVideo(
      searchQuery.query,
      page: searchQuery.page,
    );
    return result.map((it) => it.asPagedVideos());
  }

  @override
  List<FilterGroup>? get filters => [];

  @override
  List<SortOption>? get sortOptions => [];
}

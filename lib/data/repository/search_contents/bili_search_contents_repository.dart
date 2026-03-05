import 'dart:async';

import '../../../network/network_search_data_source.dart';
import '../../../utils/result.dart';
import '../../../model/data/filter_group.dart';
import '../../../model/data/sort_option.dart';
import '../../model/creator_profile.dart';
import '../../model/live_room.dart';
import '../../model/search_results.dart';
import '../../model/video_info_base.dart';
import 'search_contents_repository.dart';

class BiliSearchContentsRepository implements SearchContentsRepository {
  const BiliSearchContentsRepository({
    required NetworkSearchDataSource network
  }) : _network = network;
  
  final NetworkSearchDataSource _network;
  
  
  @override
  Future<Result<AggregateSearchResults>> searchAll(SearchQuery searchQuery) async {
    final result = await _network.searchAll(
      searchQuery.query,
      page: searchQuery.page,
    );
    return result.map((it) => it.asModel());
  }
  
  @override
  Future<Result<PagedCreatorProfile>> searchCreatorProfile(SearchQuery searchQuery) async {
    final result = await _network.searchBiliUser(
      searchQuery.query,
      page: searchQuery.page,
    );
    return result.map((it) => it.asPagedCreatorProfile());
  }
  
  @override
  Future<Result<PagedLiveRooms>> searchLiveRoom(SearchQuery searchQuery) async {
    final result = await _network.searchLiveRoom(
      searchQuery.query,
      page: searchQuery.page,
    );
    return result.map((it) => it.asPagedLiveRooms());
  }
  
  @override
  Future<Result<PagedVideos>> searchVideo(SearchQuery searchQuery) async {
    final result = await _network.searchVideo(
      searchQuery.query,
      page: searchQuery.page,
    );
    return result.map((it) => it.asPagedVideos());
  }
}
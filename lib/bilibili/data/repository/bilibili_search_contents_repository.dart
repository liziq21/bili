import 'dart:async';

import '../../../data/repository/model/live_room.dart';
import '../../../data/repository/model/search_results.dart';
import '../../../data/repository/model/video_info_base.dart';
import '../../../data/repository/search_contents/search_contents_repository.dart';
import '../../../model/data/filter_group.dart';
import '../../../model/data/sort_option.dart';
import '../../../model/creator_profile.dart';
import '../../../utils/result.dart';
import '../../network/network_search_data_source.dart';

class BilibiliSearchContentsRepository implements SearchContentsRepository {
  const BilibiliSearchContentsRepository({
    required NetworkSearchDataSource network,
  }) : _network = network;

  final NetworkSearchDataSource _network;

  @override
  Future<Result<AggregateSearchResults>> searchAll(
    SearchQuery searchQuery,
  ) async {
    final result = await _network.searchAll(
      searchQuery.query,
      page: searchQuery.page,
    );
    return result.map((it) => it.asModel());
  }

  @override
  Future<Result<PagedCreatorProfile>> searchCreatorProfile(
    SearchQuery searchQuery,
  ) async {
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


import 'dart:async';

import 'package:data/data.dart';
import 'package:bpi/bpi.dart';
import 'package:model/model.dart';

import '../model/search_results.dart';

class const BilibiliAggregateSearchRepository({
  required final NetworkSearchDataSource _network,
}) implements VideoSearchRepository {
  @override
  Future<Result<AggregateSearchPage>> search(SearchQuery searchQuery) {
    return _network
        .searchAll(searchQuery.query, page: searchQuery.pageKey)
        .then((it) => it.asModel())
        .toResult();
  }

  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];
}

class const BilibiliUserSearchRepository({
  required final NetworkSearchDataSource _network,
}) implements CreatorProfileSearchRepository {
  @override
  Future<Result<Page<CreatorProfile>>> search(SearchQuery searchQuery) {
    return _network
        .searchBiliUser(searchQuery.query, page: searchQuery.pageKey)
        .then((it) => it.asPagedCreatorProfile())
        .toResult();
  }

  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];
}

class const BilibiliLiveRoomSearchRepository({
  required final NetworkSearchDataSource _network,
}) implements LiveRoomSearchRepository {
  @override
  Future<Result<Page<LiveRoom>>> search(SearchQuery searchQuery) {
    return _network
        .searchLiveRoom(searchQuery.query, page: searchQuery.pageKey)
        .then((it) => it.asPagedLiveRooms())
        .toResult();
  }

  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];
}

class const BilibiliVideoSearchRepository({
  required final NetworkSearchDataSource _network,
}) implements VideoSearchRepository {
  @override
  Future<Result<Page<VideoInfoBase>>> search(SearchQuery searchQuery) {
    return _network
        .searchVideo(searchQuery.query, page: searchQuery.pageKey)
        .then((it) => it.asPagedVideos())
        .toResult();
  }

  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];
}

import 'dart:async';

import 'package:data/data.dart';
import 'package:bpi/bpi.dart';
import 'package:model/model.dart';

import '../model/search_results.dart';

class BilibiliAggregateSearchRepository implements VideoSearchRepository {
  const BilibiliAggregateSearchRepository({
    required NetworkSearchDataSource network,
  }) : _network = network;

  final NetworkSearchDataSource _network;

  @override
  Future<Result<AggregateSearchPage>> search(SearchQuery searchQuery) {
    return _network
        .searchAll(searchQuery.query, page: searchQuery.page)
        .then((it) => it.asModel())
        .toResult();
  }

  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];
}

class BilibiliUserSearchRepository implements CreatorProfileSearchRepository {
  const BilibiliUserSearchRepository({required NetworkSearchDataSource network})
    : _network = network;

  final NetworkSearchDataSource _network;
  @override
  Future<Result<Page<CreatorProfile>>> search(SearchQuery searchQuery) {
    return _network
        .searchBiliUser(searchQuery.query, page: searchQuery.page)
        .then((it) => it.asPagedCreatorProfile())
        .toResult();
  }

  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];
}

class BilibiliLiveRoomSearchRepository implements LiveRoomSearchRepository {
  const BilibiliLiveRoomSearchRepository({
    required NetworkSearchDataSource network,
  }) : _network = network;

  final NetworkSearchDataSource _network;

  @override
  Future<Result<Page<LiveRoom>>> search(SearchQuery searchQuery) {
    return _network
        .searchLiveRoom(searchQuery.query, page: searchQuery.page)
        .then((it) => it.asPagedLiveRooms())
        .toResult();
  }

  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];
}

class BilibiliVideoSearchRepository implements VideoSearchRepository {
  const BilibiliVideoSearchRepository({
    required NetworkSearchDataSource network,
  }) : _network = network;

  final NetworkSearchDataSource _network;

  @override
  Future<Result<Page<VideoInfoBase>>> search(SearchQuery searchQuery) {
    return _network
        .searchVideo(searchQuery.query, page: searchQuery.page)
        .then((it) => it.asPagedVideos())
        .toResult();
  }

  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];
}

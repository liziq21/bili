import 'dart:async';

import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../../model/search_results.dart';
import '../bili_remote_data_source.dart';

final class const BiliLiveRoomSearchRemoteDataSource({
  required final NetworkSearchDataSource _network,
}) extends LiveRoomSearchRemoteDataSource with BiliRemoteDataSource {
  @override
  List<FilterGroup> get filters => const [];
  @override
  List<SortOption> get sortOptions => const [];
  @override
  Future<Result<Page<LiveRoomModel>>> searchLiveRoom(
    String query, {
    int? pageKey,
  }) {
    return _network
        .searchLiveRoom(query, page: pageKey)
        .then((it) => it.asPagedLiveRooms())
        .toResult();
  }
}

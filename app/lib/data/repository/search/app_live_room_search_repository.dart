import 'package:bilibili/bilibili.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../search_contents_repository.dart';

class AppLiveRoomSearchRepository implements LiveRoomSearchRepository {
  const AppLiveRoomSearchRepository(this._remoteDataSource);

  final BilibiliSearchRemoteDataSource _remoteDataSource;

  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<Result<Page<LiveRoomModel>>> search(SearchQuery query) {
    return _remoteDataSource.searchLiveRoom(query.query, pageKey: query.pageKey);
  }
}

import 'package:data/data.dart';
import 'package:model/model.dart';

import '../search_contents_repository.dart';

class const AppLiveRoomSearchRepository(
  final LiveRoomSearchRemoteDataSource _remoteDataSource,
) implements LiveRoomSearchRepository {
  @override
  List<FilterGroup> get filters => _remoteDataSource.filters;

  @override
  List<SortOption> get sortOptions => _remoteDataSource.sortOptions;

  @override
  Future<Result<Page<LiveRoomModel>, Exception>> search(SearchQuery query) {
    return _remoteDataSource.searchLiveRoom(
      query.query,
      pageKey: query.pageKey,
    );
  }
}

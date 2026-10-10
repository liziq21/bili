import 'package:data/data.dart';
import 'package:model/model.dart';

import '../search_contents_repository.dart';

class const AppCreatorProfileSearchRepository(
  final CreatorProfileSearchRemoteDataSource _remoteDataSource,
) implements CreatorProfileSearchRepository {
  @override
  List<FilterGroup> get filters => _remoteDataSource.filters;

  @override
  List<SortOption> get sortOptions => _remoteDataSource.sortOptions;

  @override
  Future<Result<Page<CreatorProfile>>> search(SearchQuery query) {
    return _remoteDataSource.searchCreatorProfile(
      query.query,
      pageKey: query.pageKey,
    );
  }
}

import 'package:data/data.dart';
import 'package:model/model.dart';

import '../search_contents_repository.dart';

class const AppVideoSearchRepository(
  final VideoSearchRemoteDataSource _remoteDataSource,
) implements VideoSearchRepository {
  @override
  List<FilterGroup> get filters => _remoteDataSource.filters;

  @override
  List<SortOption> get sortOptions => _remoteDataSource.sortOptions;

  @override
  Future<Result<Page<VideoModel>>> search(SearchQuery query) =>
      _remoteDataSource.searchVideo(query);
}

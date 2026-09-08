import 'package:bilibili/bilibili.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../search_contents_repository.dart';

class AppVideoSearchRepository implements VideoSearchRepository {
  const AppVideoSearchRepository(this._remoteDataSource);

  final BilibiliSearchRemoteDataSource _remoteDataSource;

  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<Result<Page<VideoModel>>> search(SearchQuery query) {
    return _remoteDataSource.searchVideo(query.query, pageKey: query.pageKey);
  }
}

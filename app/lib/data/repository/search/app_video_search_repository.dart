import 'package:bilibili/bilibili.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../search_contents_repository.dart';

class const AppVideoSearchRepository(
  final BiliVideoSearchRemoteDataSource _remoteDataSource,
) implements VideoSearchRepository {
  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<Result<Page<VideoModel>>> search(SearchQuery query) {
    return _remoteDataSource.searchVideo(query.query, pageKey: query.pageKey);
  }
}

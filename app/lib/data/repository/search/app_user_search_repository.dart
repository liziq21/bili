import 'package:bilibili/bilibili.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../search_contents_repository.dart';
import '../search_suggest_repository.dart';

class AppUserSearchRepository implements CreatorProfileSearchRepository, SearchSuggestRepository {
  const AppUserSearchRepository(this._remoteDataSource);

  final BilibiliSearchRemoteDataSource _remoteDataSource;

  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<Result<Page<CreatorProfile>>> search(SearchQuery query) {
    return _remoteDataSource.searchBiliUser(query.query, pageKey: query.pageKey);
  }

  @override
  Future<Result<List<String>>> getSuggests(String query) {
    return _remoteDataSource.getSuggests(query);
  }
}

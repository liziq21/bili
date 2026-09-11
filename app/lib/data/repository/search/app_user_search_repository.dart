import 'package:bilibili/bilibili.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../search_contents_repository.dart';
import '../search_suggest_repository.dart';

class const AppUserSearchRepository(
  final BiliCreatorProfileSearchRemoteDataSource _remoteDataSource,
  final BiliSearchSuggestRemoteDataSource _suggestRemoteDataSource,
) implements CreatorProfileSearchRepository, SearchSuggestRepository {
  @override
  List<FilterGroup> get filters => const [];

  @override
  List<SortOption> get sortOptions => const [];

  @override
  Future<Result<Page<CreatorProfile>>> search(SearchQuery query) {
    return _remoteDataSource.searchCreatorProfile(
      query.query,
      pageKey: query.pageKey,
    );
  }

  @override
  Future<Result<List<String>>> getSuggests(String query) {
    return _suggestRemoteDataSource.getSuggests(query);
  }
}

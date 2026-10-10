import 'package:data/data.dart';
import 'package:model/model.dart';

import 'search_suggest_repository.dart';

class const AppSearchSuggestRepository(
  final SearchSuggestRemoteDataSource _remoteDataSource,
) implements SearchSuggestRepository {
  @override
  Future<Result<List<String>>> getSuggests(String query) =>
      _remoteDataSource.getSuggests(query);
}

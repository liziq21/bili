import 'dart:async';

import '../../../network/network_search_data_source.dart';
import '../../../utils/result.dart';
import 'search_suggest_repository.dart';

class BiliSearchSuggestRepository implements SearchSuggestRepository {
  const BiliSearchSuggestRepository({required NetworkSearchDataSource networkApi})
    : _networkApi = networkApi;
  
  final NetworkSearchDataSource _networkApi;
  
  Future<Result<Iterable<String>>> getSuggests(String query) async {
    final result = await networkApi.getSuggests(query);
    return switch (result) {
      Ok(:value) => .ok(value.tag.map((e) => e.term)),
      Error() => result,
    };
  }
}
import 'dart:async';

import '../../../network/network_search_data_source.dart';
import '../../../utils/result.dart';
import 'search_suggest_repository.dart';

class BiliSearchSuggestRepository implements SearchSuggestRepository {
  const BiliSearchSuggestRepository({
    required NetworkSearchDataSource network
  }) : _network = network;
  
  final NetworkSearchDataSource _network;
  
  @override
  Future<Result<Iterable<String>>> getSuggests(String query) async {
    final result = await _network.getSuggests(query);
    return result.map((value) =>
      value.tag.map((e) => e.term)
    );
  }
}
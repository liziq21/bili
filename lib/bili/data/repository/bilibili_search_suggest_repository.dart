import 'dart:async';

import '../../../search_suggest_repository.dart';
import '../../../utils/result.dart';
import '../../network/network_search_data_source.dart';

class BilibiliSearchSuggestRepository implements SearchSuggestRepository {
  const BilibiliSearchSuggestRepository({
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
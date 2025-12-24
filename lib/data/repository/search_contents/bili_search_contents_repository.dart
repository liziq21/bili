import 'dart:async';

import '../../../network/network_search_data_source.dart';
import '../../../utils/result.dart';
import '../../model/search_result.dart';
import 'search_contents_repository.dart';

class BiliSearchContentsRepository implements SearchContentsRepository {
  const BiliSearchContentsRepository({
    required NetworkSearchDataSource network
  }) : _network = network;
  
  final NetworkSearchDataSource _network;
  
  @override
  Future<Result<SearchResult>> searchContents(
    String searchQuery, {
    required int page,
  }) async {
    final result = await _network.search(searchQuery);
    return result.map((it) => it.asModel());
  }
}
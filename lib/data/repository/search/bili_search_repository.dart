import '../../../network/network_search_data_source.dart';
import '../../../utils/result.dart';
import '../../model/search/search_result.dart';
import 'search_epository.dart';

class BiliSearchRepository implements SearchRepository {
  const BiliSearchRepository({required NetworkSearchDataSource networkApi})
    : _networkApi = networkApi;
  
  final NetworkSearchDataSource _networkApi;
  
  Future<Result<List<SearchResult>>>search() async {
    return .ok([]);
  }
}
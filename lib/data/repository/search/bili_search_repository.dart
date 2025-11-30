import '../../../network/network_search_data_source.dart';
import '../../../utils/result.dart';
import '../../model/search/search_result.dart';
import 'SearchRepository.dart';

class BiliSearchRepository implements SearchRepository {
  const factory BiliSearchRepository({required NetworkSearchDataSource networkApi})
    : _networkApi = networkApi;
  
  final NetworkSearchDataSource _networkApi;
  
  Future<Result<List<SearchResult>>>search() async {
    return [];
  }
  
  Future<Result<List<String>>> getSearchSuggest(String term) async {
    final result = await networkApi.getSearchSuggest(tetm);
    
  }
}
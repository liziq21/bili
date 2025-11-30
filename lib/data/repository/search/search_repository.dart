import '../../../utils/result.dart';
import '../../model/search/search_result.dart';

abstract class SearchRepository {
  Future<Result<List<SearchResult>>> search();
  Future<Result<List<String>>> getSearchSuggest(String term);
}
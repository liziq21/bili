import '../../model/search/search_result.dart';
import '../../model/search/search_suggest.dart';
import '../../../utils/result.dart';

abstract class SearchRepository {
  Future<Result<List<SearchResult>>> search();
  Future<Result<List<SearchSuggest>>> searchSuggest();
}
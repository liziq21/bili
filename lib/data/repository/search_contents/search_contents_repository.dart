import 'dart:async';

import '../../../utils/result.dart';
import '../../model/search/search_result.dart';

abstract class SearchContentsRepository {
  Future<Result<List<SearchResult>>> searchContents(String searchQuery);
}
import 'dart:async';

import '../../../utils/result.dart';
import '../../model/search_result.dart';

abstract class SearchContentsRepository {
  Future<Result<List<SearchResult>>> searchContents(String searchQuery);
}
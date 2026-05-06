import 'dart:async';

import '../../../utils/result.dart';

abstract class SearchSuggestRepository {
  Future<Result<List<String>>> getSuggests(String query);
}


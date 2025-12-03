import 'dart:async';

import '../../../utils/result.dart';

abstract class SearchSuggestRepository {
  Future<Result<Iterable<String>>> getSuggests(String query);
}
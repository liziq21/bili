import 'dart:async';

import 'package:model/model.dart';

abstract class SearchSuggestRepository {
  Future<Result<List<String>>> getSuggests(String query);
}

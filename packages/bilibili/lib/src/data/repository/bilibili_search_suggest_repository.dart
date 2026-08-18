import 'dart:async';

import 'package:model/model.dart';
import 'package:bpi/bpi.dart';
import 'package:data/data.dart';

class const BilibiliSearchSuggestRepository({required this._network})
    implements SearchSuggestRepository {
  final NetworkSearchDataSource _network;

  @override
  Future<Result<List<String>>> getSuggests(String query) {
    return _network
        .getSuggests(query)
        .then((value) => value.tag.map((e) => e.term).toList())
        .toResult();
  }
}

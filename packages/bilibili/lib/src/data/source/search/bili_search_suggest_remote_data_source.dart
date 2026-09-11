import 'dart:async';

import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../bili_remote_data_source.dart';

final class const BiliSearchSuggestRemoteDataSource({
  required final NetworkSearchDataSource _network,
}) extends SearchSuggestRemoteDataSource with BiliRemoteDataSource {
  @override
  Future<Result<List<String>>> getSuggests(String query) {
    return _network
        .getSuggests(query)
        .then((value) => value.tag.map((e) => e.term).toList())
        .toResult();
  }
}

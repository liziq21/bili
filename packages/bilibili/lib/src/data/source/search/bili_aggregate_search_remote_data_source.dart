import 'dart:async';

import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../../model/search_results.dart';
import '../bili_remote_data_source.dart';

final class const BiliAggregateSearchRemoteDataSource({
  required final NetworkSearchDataSource _network,
}) extends AggregateSearchRemoteDataSource with BiliRemoteDataSource {
  @override
  List<FilterGroup> get filters => const [];
  @override
  List<SortOption> get sortOptions => const [];
  @override
  Future<Result<AggregateSearchPage>> searchAll(String query, {int? pageKey}) {
    return _network
        .searchAll(query, page: pageKey)
        .then((it) => it.asModel())
        .toResult();
  }
}

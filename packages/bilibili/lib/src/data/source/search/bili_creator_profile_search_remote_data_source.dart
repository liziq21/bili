import 'dart:async';

import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../../model/search_results.dart';
import '../bili_remote_data_source.dart';

final class const BiliCreatorProfileSearchRemoteDataSource({
  required final NetworkSearchDataSource _network,
}) extends CreatorProfileSearchRemoteDataSource with BiliRemoteDataSource {
  @override
  List<FilterGroup> get filters => const [];
  @override
  List<SortOption> get sortOptions => const [];
  @override
  Future<Result<Page<CreatorProfile>>> searchCreatorProfile(
    String query, {
    int? pageKey,
  }) {
    return _network
        .searchBiliUser(query, page: pageKey)
        .then((it) => it.asPagedCreatorProfile())
        .toResult();
  }
}

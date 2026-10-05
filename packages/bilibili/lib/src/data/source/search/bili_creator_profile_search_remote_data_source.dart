import 'dart:async';

import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../../model/search_results.dart';
import '../bili_remote_data_source.dart';

final class const BiliCreatorProfileSearchRemoteDataSource({
  required final NetworkSearchDataSource _network,
}) extends CreatorProfileSearchRemoteDataSource with BiliRemoteDataSource {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  @override
  List<FilterGroup> get filters => const [];
  @override
  List<SortOption> get sortOptions => const [];
  @override
  Future<Result<Page<CreatorProfile>>> searchCreatorProfile(
    String query, {
    int? pageKey,
  }) {
    final cleanQuery = query.replaceAll(_controlChars, '').trim();
    if (cleanQuery.isEmpty) {
      final targetPage = pageKey ?? 1;
      return Future.value(
        Result.ok(
          Page<CreatorProfile>(
            number: targetPage,
            totalPages: targetPage,
            data: const [],
          ),
        ),
      );
    }
    return _network
        .searchBiliUser(cleanQuery, page: pageKey)
        .then((it) => it.asPagedCreatorProfile())
        .toResult();
  }
}

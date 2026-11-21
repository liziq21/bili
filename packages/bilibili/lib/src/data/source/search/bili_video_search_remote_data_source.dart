import 'dart:async';

import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../../../search/search_filter.dart';
import '../../../search/sort.dart';
import '../../model/search_results.dart';
import '../bili_remote_data_source.dart';

final class const BiliVideoSearchRemoteDataSource({
  required final NetworkSearchDataSource _network,
}) extends VideoSearchRemoteDataSource with BiliRemoteDataSource {
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  @override
  List<FilterGroup> get filters => const [VideoDurationFilter()];
  @override
  List<SortOption> get sortOptions => PhotoOrVideoSearchSort.values;

  @override
  Future<Result<Page<VideoModel>, Exception>> searchVideo(
    SearchQuery searchQuery,
  ) {
    final cleanQuery = searchQuery.query.replaceAll(_controlChars, '').trim();
    if (cleanQuery.isEmpty) {
      final targetPage = searchQuery.pageKey;
      return Future.value(
        Result.success(
          Page<VideoModel>(
            number: targetPage,
            totalPages: targetPage,
            data: const [],
          ),
        ),
      );
    }
    return _network
        .searchVideo(
          cleanQuery,
          page: searchQuery.pageKey,
          order: searchQuery.sortOption?.toQueryParams()['order'],
          duration: _durationParam(searchQuery.filters),
        )
        .then((it) => it.asPagedVideos())
        .toResult();
  }

  /// B 站时长筛选值：1 为 10 分钟以下，2 为 10–30 分钟，3 为 30–60 分钟，
  /// 4 为 60 分钟以上；不限时不传该参数。
  String? _durationParam(List<FilterGroup> filters) {
    for (final filter in filters) {
      if (filter is! SingleFilterGroup || filter.key != 'duration') continue;
      return switch (filter.selection) {
        VideoDurationFilterOption.allDuration => null,
        VideoDurationFilterOption.below10Minutes => '1',
        VideoDurationFilterOption.tenTo30Minutes => '2',
        VideoDurationFilterOption.thirtyTo60Minutes => '3',
        VideoDurationFilterOption.above60Minutes => '4',
        null => null,
        _ => null,
      };
    }
    return null;
  }
}

import 'dart:async';

import 'package:model/model.dart';

import '../model/filter_group.dart';
import '../model/sort_option.dart';
import '../model/creator_profile.dart';
import '../model/live_room.dart';
import '../model/paged_result.dart';
import '../model/video_info_base.dart';

import 'package:meta/meta.dart';

@immutable
class const SearchQuery({
  required final String query,
  final int pageKey = 1,
  final SortOption? sortOption,
  final List<FilterGroup> filters = const [],
}) {
  Map<String, String> get parameters => <String, String>{
    ...?sortOption?.toQueryParams(),
    for (final filter in filters) ...filter.toQueryParams(),
  };

  SearchQuery copyWith({
    String? query,
    int? pageKey,
    SortOption? sortOption,
    List<FilterGroup>? filters,
  }) {
    return SearchQuery(
      query: query ?? this.query,
      pageKey: pageKey ?? this.pageKey,
      sortOption: sortOption ?? this.sortOption,
      filters: filters ?? this.filters,
    );
  }
}

abstract interface class SearchContentsRepository<T> {
  List<SortOption> get sortOptions;
  List<FilterGroup> get filters;

  Future<Result<Page<T>>> search(SearchQuery searchQuery);
}

typedef VideoSearchRepository = SearchContentsRepository<VideoInfoBase>;
typedef CreatorProfileSearchRepository =
    SearchContentsRepository<CreatorProfile>;
typedef LiveRoomSearchRepository = SearchContentsRepository<LiveRoom>;
typedef AggregateSearchRepository = VideoSearchRepository; // 或者是特定的聚合 Model

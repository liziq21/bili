import 'dart:async';

import 'package:model/model.dart';
import '../model/filter_group.dart';
import '../model/sort_option.dart';
import '../model/creator_profile.dart';
import '../model/live_room.dart';
import '../model/paged_result.dart';
import '../model/video_info_base.dart';

class SearchQuery {
  SearchQuery(
    this.query, {
    this.page,
    SortOption? sortOption,
    List<FilterGroup>? filters,
  }) : parameters = {
         ...?sortOption?.toQueryParams(),
         if (filters != null)
           for (final filter in filters) ...filter.toQueryParams(),
       };

  final String query;
  final int? page;
  final Map<String, String> parameters;
}

abstract interface class SearchContentsRepository<T> {
  //const SearchContentsRepository();
  List<SortOption> get sortOptions;
  List<FilterGroup> get filters;

  Future<Result<Page<T>>> search(SearchQuery searchQuery);
}

typedef VideoSearchRepository = SearchContentsRepository<VideoInfoBase>;
typedef CreatorProfileSearchRepository =
    SearchContentsRepository<CreatorProfile>;
typedef LiveRoomSearchRepository = SearchContentsRepository<LiveRoom>;
typedef AggregateSearchRepository = VideoSearchRepository; // 或者是特定的聚合 Model

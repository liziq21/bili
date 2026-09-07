import 'dart:async';

import 'package:data/data.dart';
import 'package:model/model.dart';

abstract interface class SearchContentsRepository<T> {
  List<SortOption> get sortOptions;
  List<FilterGroup> get filters;

  Future<Result<Page<T>>> search(SearchQuery searchQuery);
}

typedef VideoSearchRepository = SearchContentsRepository<VideoModel>;
typedef CreatorProfileSearchRepository =
    SearchContentsRepository<CreatorProfile>;
typedef LiveRoomSearchRepository = SearchContentsRepository<LiveRoomModel>;
typedef AggregateSearchRepository = SearchContentsRepository<AggregateSearchPage>;

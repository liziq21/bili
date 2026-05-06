import 'dart:async';

import '../../../utils/result.dart';
import '../../../model/data/filter_group.dart';
import '../../../model/data/sort_option.dart';
import '../../model/creator_profile.dart';
import '../../model/live_room.dart';
import '../../model/paged_result.dart';
import '../../model/search_results.dart';
import '../../model/video_info_base.dart';

class SearchQuery {
  const SearchQuery(this.query, {this.page, this.sortOption, this.filters});

  final String query;
  final int? page;
  final SortOption? sortOption;
  final List<FilterGroup>? filters;
}

abstract class SearchContentsRepository {
  Future<Result<AggregateSearchPage>> searchAll(SearchQuery searchQuery);

  Future<Result<Page<CreatorProfile>>> searchCreatorProfile(
    SearchQuery searchQuery,
  );

  Future<Result<Page<LiveRoom>>> searchLiveRoom(SearchQuery searchQuery);

  Future<Result<Page<VideoInfoBase>>> searchVideo(SearchQuery searchQuery);
}

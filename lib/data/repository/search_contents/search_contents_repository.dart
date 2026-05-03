import 'dart:async';

import '../../../utils/result.dart';
import '../../../model/data/filter_group.dart';
import '../../../model/data/sort_option.dart';
import '../../model/creator_profile.dart';
import '../../model/live_room.dart';
import '../../model/search_results.dart';
import '../../model/video_info_base.dart';

abstract class SearchQuery {
  const SearchQuery(this.query, {this.page, this.sortOption, this.filters});

  final String query;
  final String? page;
  final SortOption? sortOption;
  final List<FilterGroup>? filters;
}

abstract class SearchContentsRepository {
  Future<Result<AggregateSearchResults>> searchAll(SearchQuery searchQuery);

  Future<Result<PagedCreatorProfile>> searchCreatorProfile(
    SearchQuery searchQuery,
  );

  Future<Result<PagedLiveRooms>> searchLiveRoom(SearchQuery searchQuery);

  Future<Result<PagedVideos>> searchVideo(SearchQuery searchQuery);
}


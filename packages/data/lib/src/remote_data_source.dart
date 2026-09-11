import 'package:model/model.dart';

import 'model/creator_profile_model.dart';
import 'model/filter_group.dart';
import 'model/live_room_model.dart';
import 'model/paged_result.dart';
import 'model/search_results.dart';
import 'model/sort_option.dart';
import 'model/video_model.dart';

abstract class const RemoteDataSource() {
  String get sourceId;
}

abstract class const SearchRemoteDataSource() extends RemoteDataSource {
  List<FilterGroup> get filters => const [];
  List<SortOption> get sortOptions => const [];
}

abstract class const AggregateSearchRemoteDataSource()
    extends SearchRemoteDataSource {
  Future<Result<AggregateSearchPage>> searchAll(String query, {int? pageKey});
}

abstract class const CreatorProfileSearchRemoteDataSource()
    extends SearchRemoteDataSource {
  Future<Result<Page<CreatorProfile>>> searchCreatorProfile(
    String query, {
    int? pageKey,
  });
}

abstract class const LiveRoomSearchRemoteDataSource()
    extends SearchRemoteDataSource {
  Future<Result<Page<LiveRoomModel>>> searchLiveRoom(
    String query, {
    int? pageKey,
  });
}

abstract class const VideoSearchRemoteDataSource()
    extends SearchRemoteDataSource {
  Future<Result<Page<VideoModel>>> searchVideo(String query, {int? pageKey});
}

abstract class const SearchSuggestRemoteDataSource() extends RemoteDataSource {
  Future<Result<List<String>>> getSuggests(String query);
}

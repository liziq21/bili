import 'package:model/model.dart';

import 'model/creator_profile_model.dart';
import 'model/live_room_model.dart';
import 'model/paged_result.dart';
import 'model/search_results.dart';
import 'model/video_model.dart';

/// Base class for all remote data sources.
///
/// Each service source module (e.g., `packages/bilibili`) should extend this
/// class and provide its own [sourceId] to identify the origin of the data.
/// The [sourceId] is used by the `app/lib/data` layer when persisting data
/// to the local database, so that cached records can be attributed to their
/// original service.
abstract class RemoteDataSource {
  /// Identifies the service this data source fetches from (e.g., `'bilibili'`).
  String get sourceId;
}

/// Remote data source contract for search-related operations.
abstract class SearchRemoteDataSource extends RemoteDataSource {
  Future<Result<AggregateSearchPage>> searchAll(String query, {int? pageKey});
  Future<Result<Page<CreatorProfile>>> searchBiliUser(String query, {int? pageKey});
  Future<Result<Page<LiveRoomModel>>> searchLiveRoom(String query, {int? pageKey});
  Future<Result<Page<VideoModel>>> searchVideo(String query, {int? pageKey});
  Future<Result<List<String>>> getSuggests(String query);
}

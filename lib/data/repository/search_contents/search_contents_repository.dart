import 'dart:async';

import '../../../utils/result.dart';
import '../../model/creator_profile.dart';
import '../../model/live_room.dart';
import '../../model/search_results.dart';
import '../../model/video_info_base.dart';

abstract class SearchContentsRepository {
  Future<Result<AllSearchResults>> searchContents(String searchQuery, {int? page});
  
  Future<Result<SearchResults<CreatorProfile>>> searchCreatorProfile(String searchQuery, {int? page});
  
  Future<Result<SearchResults<LiveRoom>>> searchLiveRoom(String searchQuery, {int? page});
  
  Future<Result<SearchResults<VideoInfoBase>>> searchVideo(String searchQuery, {int? page});
}
import 'dart:async';

import '../../../network/network_search_data_source.dart';
import '../../../utils/result.dart';
import '../../model/creator_profile.dart';
import '../../model/live_room.dart';
import '../../model/search_results.dart';
import '../../model/video_info_base.dart';
import 'search_contents_repository.dart';

class BiliSearchContentsRepository implements SearchContentsRepository {
  const BiliSearchContentsRepository({
    required NetworkSearchDataSource network
  }) : _network = network;
  
  final NetworkSearchDataSource _network;
  
  @override
  Future<Result<AllSearchResults>> searchContents(
    String searchQuery, {
    required int page,
  }) async {
    final result = await _network.search(
      searchQuery,
      page: page,
    );
    return result.map((it) {
      final biliUser = it.biliUser.firstOrNull;
      return AllSearchResults(
        page: it.page,
        numPages: it.numPages,
        creatorProfile: biliUser?.asModel(),
        creatorProfileVideos: biliUser?.res.map((e) => e.asModel()),
        videos: it.videos.map((e) => e.asModel()),
      );
    });
  }
  
  @override
  Future<Result<SearchResults<CreatorProfile>>> searchCreatorProfile(
    String searchQuery, {
    required int page,
  }) async {
    final result = await _network.searchBiliUser(
      searchQuery,
      page: page,
    );
    return result.map((it) => SearchResults(
      page: it.page,
      numPages: it.numPages,
      creatorProfile: it.biliUser.map((e) => e.asModel()),
    ));
  }
  
  @override
  Future<Result<SearchResults<LiveRoom>>> searchLiveRoom(
    String searchQuery, {
    required int page,
  }) async {
    final result = await _network.searchLiveRoom(
      searchQuery,
      page: page,
    );
    return result.map((it) => SearchResults(
      page: it.page,
      numPages: it.numPages,
      creatorProfile: it.liveRoom.map((e) => e.asModel()),
    ));
  }

  @override
  Future<Result<SearchResults<VideoInfoBase>>> searchVideo(
    String searchQuery, {
    required int page,
  }) async {
    final result = await _network.searchVideo(
      searchQuery,
      page: page,
    );
    return result.map((it) => SearchResults(
      page: it.page,
      numPages: it.numPages,
      resutls: it.videos.map((e) => e.asModel()),
    ));
  }
}
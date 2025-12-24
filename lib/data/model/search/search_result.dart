import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../network/model/search/network_search_result.dart';
import 'concrete_results/bili_user_search_result.dart';
import 'concrete_results/live_room_search_result.dart';
import 'concrete_results/live_user_search_result.dart';
import 'concrete_results/video_search_result.dart';

part 'search_result.freezed.dart';

@freezed
abstract class SearchResult with _$SearchResult {
  const factory SearchResult({
    required int page,
    required int pagesize,
    required int numResults,
    required int numPages,
    List<BiliUserSearchResult> biliUserResults,
    List<LiveRoomSearchResult> liveRoomResults,
    List<LiveUserSearchResult> liveUserResults,
    List<VideoSearchResult> videoResults,
  }) = _SearchResult;
}

extension NetworkSearchResultX on NetworkSearchResult {
  SearchResult asModel() => SearchResult(
    page: page,
    pagesize: pagesize,
    numResults: numResults,
    numPages: numPages,
    biliUserResults: result.biliUser.map((it) => it.asModel()).toList();
    liveRoomResults: result.liveRoom.map((it) => it.asModel()).toList();
    liveUserResults: result.liveUser.map((it) => it.asModel()).toList();
    videoResults: result.video.map((it) => it.asModel()).toList() ;
  );
}
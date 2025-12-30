import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../network/model/search/network_search_result.dart';
import 'creator_profile.dart';
import 'video_info_base.dart';

part 'search_results.freezed.dart';

@freezed
abstract class AllSearchResults with _$AllSearchResults {
  const factory BiliSearchResults({
    required int page,
    required int numPages,
    required List<VideoInfoBase> videos,
    CreatorProfile? creatorProfile,
    List<VideoInfoBase>? creatorProfileVideos,
  }) = _AllSearchResults;
}

@freezed
class SearchResults<T> with _$SearchResults<T>{
  const factory SearchResults({
    required int page,
    required int numPages,
    required List<T> results,
  }) = _SearchResults;
}

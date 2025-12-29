import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../network/model/search/network_search_result.dart';
import 'creator_profile.dart';
import 'video_info_base.dart';

class AllSearchResults {
  final int page;
  final int numPages;
  final CreatorProfile? creatorProfile;
  final List<VideoInfoBase>? creatorProfileVideos;
  final List<VideoInfoBase> videos;

  const BiliSearchResults({
    required this.page,
    required this.numPages,
    this.creatorProfile,
    this.creatorProfileVideos,
    required this.videos,
  });
}

class SearchResults<T> {
  final int page;
  final int numPages;
  final List<T> results;

  const VideoSearchResults({
    required this.page,
    required this.numPages,
    required this.results,
  });
}

import 'creator_profile.dart';
import 'live_room.dart';
import 'video_info_base.dart';
import '../../network/model/search/network_search_result.dart';
import '../../../data/model/search_results.dart';
import '../../../data/model/paged_result.dart';
import '../../../data/model/live_room.dart';
import '../../../data/model/creator_profile.dart';
import '../../../data/model/video_info_base.dart';

extension NetworkSearchResultWrapperE on NetworkSearchResult {
  AggregateSearchPage asModel() {
    final user = result.biliUser.firstOrNull;
    return .new(
      number: page,
      totalPages: numPages,
      data: result.video.map((it) => it.asModel()).toList(),
      creatorProfile: user?.asModel(),
      creatorProfileVideos: user?.res.map((it) => it.asModel()).toList(),
    );
  }

  Page<LiveRoom> asPagedLiveRooms() {
    return .new(
      page: result.page,
      totalPages: result.numPages,
      data: result.liveRoom.map((it) => it.asModel()),
    );
  }

  PagedCreatorProfile asPagedCreatorProfile() {
    return PagedCreatorProfile(
      page: result.page,
      totalPages: result.numPages,
      data: result.biliUser.map((it) => it.asModel()),
    );
  }

  PagedVideos asPagedVideos() {
    return PagedLiveRooms(
      page: result.page,
      totalPages: result.numPages,
      data: result.video.map((it) => it.asModel()),
    );
  }
}

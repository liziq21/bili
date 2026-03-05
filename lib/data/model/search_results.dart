import '../../../network/model/search/network_search_result.dart';
import 'creator_profile.dart';
import 'paged_result.dart';
import 'video_info_base.dart';

typedef PagedCreatorProfile = PagedResult<CreatorProfile>;
typedef PagedVideos = PagedResult<VideoInfoBase>;
typedef PagedLiveRooms = PagedResult<LiveRoomInfoBase>;

class AggregateSearchResults extends PagedResult<VideoInfoBase> {
  AggregateSearchResults({
    required super.page,
    required super.totalPages,
    required super.data,
    this.creatorProfile,
    this.creatorProfileVideos,
  });

  final CreatorProfile? creatorProfile;
  final List<VideoInfoBase>? creatorProfileVideos;
}

extension NetworkSearchResultWrapperX on NetworkSearchResult {
  AggregateSearchResults asModel() {
    final user = biliUser.firstOrNull;
    return AggregateSearchResults(
      page: result.page,
      totalPages: result.numPages,
      data: result.video.map((it) => it.asModel()),
      creatorProfile: user?.asModel(),
      creatorProfileVideos: user?.res.map((e) => e.asModel()),
    );
  );
  
  PagedLiveRooms asPagedLiveRooms() {
    return PagedLiveRooms(
      page: result.page,
      totalPages: result.numPages,
      data: result.liveRoom.map((it) => it.asModel()),
    );
  );
  
  PagedCreatorProfile asPagedCreatorProfile() {
    return PagedCreatorProfile(
      page: result.page,
      totalPages: result.numPages,
      data: result.biliUser.map((it) => it.asModel()),
    );
  );
  
  PagedVideos asPagedVideos() {
    return PagedLiveRooms(
      page: result.page,
      totalPages: result.numPages,
      data: result.video.map((it) => it.asModel()),
    );
  );
}

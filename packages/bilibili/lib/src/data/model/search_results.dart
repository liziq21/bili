import 'package:bpi/bpi.dart';
import 'package:data/data.dart';

import 'creator_profile.dart';
import 'live_room.dart';
import 'video_model.dart';

extension NetworkSearchResultWrapperE on NetworkSearchResult {
  AggregateSearchPage asModel() {
    final user = result.biliUser.firstOrNull;
    return AggregateSearchPage(
      number: page,
      totalPages: numPages,
      data: result.video.map((it) => it.asModel()).toList(),
      creatorProfile: user?.asModel(),
      creatorProfileVideos: user?.res.map((it) => it.asModel()).toList(),
    );
  }

  Page<LiveRoomModel> asPagedLiveRooms() {
    return Page<LiveRoomModel>(
      number: page,
      totalPages: numPages,
      data: result.liveRoom.map((it) => it.asModel()).toList(),
    );
  }

  Page<CreatorProfile> asPagedCreatorProfile() {
    return Page<CreatorProfile>(
      number: page,
      totalPages: numPages,
      data: result.biliUser.map((it) => it.asModel()).toList(),
    );
  }

  Page<VideoModel> asPagedVideos() {
    return Page<VideoModel>(
      number: page,
      totalPages: numPages,
      data: result.video.map((it) => it.asModel()).toList(),
    );
  }
}

import 'package:bpi/bpi.dart';
import 'package:data/data.dart';

import '../../bili_utils.dart';

extension NetworkLiveRoomSearchResultX on NetworkLiveRoomSearchResult {
  LiveRoomModel asModel() => LiveRoomModel(
    id: roomid,
    title: title.parsedTitle(),
    url: 'https://live.bilibili.com/$roomid',
    isLive: liveStatus == 1,
    thumbnailUrl: normalizeBiliUrl(cover),
    creatorProfileName: uname,
    creatorProfileId: '$uid',
  );
}

extension NetworkLiveRecommendedRoomX on NetworkLiveRecommendedRoom {
  LiveRoomModel asModel() => LiveRoomModel(
    id: roomId,
    title: title?.trim() ?? '',
    url: 'https://live.bilibili.com/$roomId',
    // 推荐接口只返回正在开播的房间。
    isLive: true,
    thumbnailUrl: normalizeBiliUrl(cover),
    creatorProfileName: uname,
    creatorProfileId: uid == null ? null : '$uid',
  );
}

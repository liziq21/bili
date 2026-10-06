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

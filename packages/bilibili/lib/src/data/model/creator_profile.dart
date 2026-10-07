import 'package:bpi/bpi.dart';
import 'package:data/data.dart';

import '../../bili_utils.dart';

extension NetworkBiliUserSearchResultX on NetworkBiliUserSearchResult {
  CreatorProfile asModel() => CreatorProfile(
    id: '$mid',
    name: uname,
    thumbnailUrl: normalizeBiliUrl(upic),
    isLive: isLive == 1,
    liveRoomId: roomId,
    subscribers: fans,
    videos: videos,
  );
}

extension NetworkLiveUserSearchResultX on NetworkLiveUserSearchResult {
  CreatorProfile asModel() => CreatorProfile(
    id: '$uid',
    name: uname.parsedTitle(),
    thumbnailUrl: normalizeBiliUrl(uface),
    isLive: isLive,
    liveRoomId: roomid,
  );
}

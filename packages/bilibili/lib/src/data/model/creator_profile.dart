import 'package:bpi/bpi.dart';
import 'package:data/data.dart';

import '../../bili_utils.dart';

extension NetworkBiliUserSearchResultX on NetworkBiliUserSearchResult {
  CreatorProfile asModel() => CreatorProfile(
    id: '$mid',
    name: uname,
    thumbnailUrl: normalizeBiliUrl(upic),
    description: usign,
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

extension NetworkBiliUserCardDataX on NetworkBiliUserCardData {
  /// 名片接口不返回直播状态，该项保持未知。
  CreatorProfile asModel() => CreatorProfile(
    id: card.mid,
    name: card.name,
    thumbnailUrl: normalizeBiliUrl(card.face),
    description: card.sign,
    subscribers: follower ?? card.fans,
    videos: archiveCount,
  );
}

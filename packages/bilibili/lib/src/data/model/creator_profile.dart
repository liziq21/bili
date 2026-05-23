import 'package:bpi/bpi.dart';
import 'package:data/data.dart';

extension NetworkBiliUserSearchResultX on NetworkBiliUserSearchResult {
  CreatorProfile asModel() => CreatorProfile(
    id: mid,
    name: uname,
    thumbnailUrl: 'https:$upic',
    isLive: isLive == 1,
    roomId: roomId,
    subscribers: fans,
    videos: videos,
  );
}

extension NetworkLiveUserSearchResultX on NetworkLiveUserSearchResult {
  CreatorProfile asModel() => CreatorProfile(
    id: uid,
    name: uname.parsedTitle(),
    thumbnailUrl: 'https:$uface',
    isLive: isLive,
    roomId: roomid,
  );
}

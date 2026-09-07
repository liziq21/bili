import 'package:bpi/bpi.dart';
import 'package:data/data.dart';

extension NetworkLiveRoomSearchResultX on NetworkLiveRoomSearchResult {
  LiveRoomModel asModel() => LiveRoomModel(
    id: roomid,
    title: title.parsedTitle(),
    url: 'https://live.bilibili.com/$roomid',
    isLive: liveStatus == 1,
    thumbnailUrl: 'https:$cover',
    creatorProfileName: uname,
    creatorProfileId: '$uid',
  );
}

import '../../network/model/search/concrete_results/network_live_room_search_result.dart';
import '../../../data/model/live_room.dart';

extension NetworkLiveRoomSearchResultX on NetworkLiveRoomSearchResult {
  LiveRoom asModel() => LiveRoom(
    id: roomid,
    title: title.parsedTitle(),
    coverUrl: 'https:$cover',
    isLive: liveStatus == 1,
    cateName: cateName,
    uid: uid,
    uname: uname,
  );
}


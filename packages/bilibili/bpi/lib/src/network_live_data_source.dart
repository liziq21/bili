import 'model/live/network_live_danmaku_info.dart';
import 'model/live/network_live_recommended_rooms.dart';
import 'model/live/network_live_room_base_info.dart';
import 'model/live/network_live_room_detail.dart';
import 'model/live/network_live_room_play_info.dart';
import 'model/live/network_live_status_by_uids.dart';

abstract interface class NetworkLiveDataSource {
  Future<NetworkLiveRoomDetail> getLiveRoomDetail({required int roomId});

  Future<NetworkLiveRoomBaseInfo> getLiveRoomBaseInfo({
    required List<int> roomIds,
  });

  Future<NetworkLiveStatusByUids> getLiveStatusByUids({
    required List<int> uids,
  });

  Future<NetworkLiveRecommendedRooms> getRecommendedLiveRooms({
    int pageSize = 30,
  });

  Future<NetworkLiveRoomPlayInfo> getLiveRoomPlayInfo({
    required int roomId,
    int qn = 10000,
    String protocol = '0,1',
    String format = '0,1,2',
    String codec = '0,1',
    String platform = 'web',
    int ptype = 8,
  });

  Future<NetworkLiveDanmakuInfo> getDanmuInfo({required int roomId});
}

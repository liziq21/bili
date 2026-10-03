import 'model/live/network_live_room_detail.dart';
import 'model/live/network_live_room_play_info.dart';

abstract interface class NetworkLiveDataSource {
  Future<NetworkLiveRoomDetail> getLiveRoomDetail({required int roomId});

  Future<NetworkLiveRoomPlayInfo> getLiveRoomPlayInfo({
    required int roomId,
    int qn = 10000,
    String protocol = '0,1',
    String format = '0,1,2',
    String codec = '0,1',
    String platform = 'web',
    int ptype = 8,
  });
}

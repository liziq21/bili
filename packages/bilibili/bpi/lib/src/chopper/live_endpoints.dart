import '../model/live/network_live_danmaku_info.dart';
import '../model/live/network_live_recommended_rooms.dart';
import '../model/live/network_live_room_base_info.dart';
import '../model/live/network_live_room_detail.dart';
import '../model/live/network_live_room_play_info.dart';
import '../model/live/network_live_status_by_uids.dart';
import '../network_live_data_source.dart';
import 'bili_network_client.dart';

mixin LiveEndpoints on BiliNetworkClient implements NetworkLiveDataSource {
  @override
  Future<NetworkLiveRoomBaseInfo> getLiveRoomBaseInfo({
    required List<int> roomIds,
  }) => api.getLiveRoomBaseInfo(roomIds: roomIds);

  @override
  Future<NetworkLiveStatusByUids> getLiveStatusByUids({
    required List<int> uids,
  }) => api.getLiveStatusByUids(uids: uids);

  @override
  Future<NetworkLiveRecommendedRooms> getRecommendedLiveRooms({
    int pageSize = 30,
  }) => api.getRecommendedLiveRooms(pageSize: pageSize);

  @override
  Future<NetworkLiveRoomDetail> getLiveRoomDetail({required int roomId}) =>
      api.getLiveRoomDetail(roomId: roomId);

  @override
  Future<NetworkLiveRoomPlayInfo> getLiveRoomPlayInfo({
    required int roomId,
    int qn = 10000,
    String protocol = '0,1',
    String format = '0,1,2',
    String codec = '0,1',
    String platform = 'web',
    int ptype = 8,
  }) => api.getLiveRoomPlayInfo(
    roomId: roomId,
    qn: qn,
    protocol: protocol,
    format: format,
    codec: codec,
    platform: platform,
    ptype: ptype,
  );

  @override
  Future<NetworkLiveDanmakuInfo> getDanmuInfo({required int roomId}) =>
      api.getDanmuInfo(roomId: roomId);
}

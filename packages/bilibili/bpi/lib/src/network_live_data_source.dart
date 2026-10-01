import 'model/live/network_live_room_detail.dart';

abstract interface class NetworkLiveDataSource {
  Future<NetworkLiveRoomDetail> getLiveRoomDetail({required int roomId});
}

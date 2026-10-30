import 'model/live/network_live_room_detail.dart';
import 'model/live/network_live_room_play_info.dart';
import 'model/live/network_live_danmaku.dart';

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

  /// Create a WebSocket connection for live danmaku.
  ///
  /// Returns a stream of parsed danmaku messages. The connection handles
  /// handshake, heartbeat, and message parsing automatically.
  /// Call [close] on the returned controller to disconnect.
  LiveDanmakuConnection connectLiveDanmaku({
    required int roomId,
    required String token,
    int uid = 0,
    LiveDanmakuProtocolVersion protocolVersion = LiveDanmakuProtocolVersion.v2,
  });
}

/// Controller for a live danmaku WebSocket connection.
abstract interface class LiveDanmakuConnection {
  /// Stream of parsed danmaku messages.
  Stream<LiveDanmakuMessage> get messages;

  /// Whether the connection is currently open.
  bool get isConnected;

  /// Close the WebSocket connection.
  Future<void> close();
}

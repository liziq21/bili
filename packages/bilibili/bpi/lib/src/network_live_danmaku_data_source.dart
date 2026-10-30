import 'model/live/live_danmaku.dart';

/// Live danmaku WebSocket connection state.
enum LiveDanmakuConnectionState {
  disconnected,
  connecting,
  connected,
  authenticating,
  authenticated,
  reconnecting,
  failed,
}

/// Live danmaku WebSocket client interface.
abstract interface class NetworkLiveDanmakuDataSource {
  /// Current connection state stream.
  Stream<LiveDanmakuConnectionState> get connectionStateStream;

  /// Incoming danmaku messages stream.
  Stream<LiveDanmakuMessage> get messageStream;

  /// Incoming danmaku comments stream (filtered from messageStream).
  Stream<LiveDanmakuComment> get commentStream;

  /// Connect to live danmaku WebSocket.
  ///
  /// [auth] contains roomId and token from [LiveDanmakuAuth].
  Future<void> connect(LiveDanmakuAuth auth);

  /// Disconnect from WebSocket.
  Future<void> disconnect();

  /// Send heartbeat manually (normally auto-sent).
  Future<void> sendHeartbeat();

  /// Whether currently connected and authenticated.
  bool get isConnected;
}

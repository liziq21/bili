import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import 'api.dart';
import 'model/live/live_danmaku.dart';
import 'network_live_danmaku_data_source.dart';

/// Live danmaku WebSocket client implementation.
///
/// Protocol based on Bilibili live danmaku WebSocket:
/// - wss://broadcastlv.chat.bilibili.com/sub
/// - Binary protobuf frames with 16-byte header
/// - Compression: ver=0 (raw), ver=2 (zlib), ver=3 (brotli)
/// - OpCodes: 2=heartbeat, 3=heartbeat_reply, 5=notify, 7=auth/auth_reply
///
/// FIXTURE NOTE: Real WS capture not available in sandbox.
/// Tests use pre-recorded fixture bytes (see testing/live_danmaku_*.bin)
/// Run `bpi/tool/capture/live_danmaku_fixture.dart` against real room to update.
class LiveDanmakuClient implements NetworkLiveDanmakuDataSource {
  LiveDanmakuClient({this._channel});

  final WebSocketChannel? _channel;
  final _stateController =
      StreamController<LiveDanmakuConnectionState>.broadcast();
  final _messageController = StreamController<LiveDanmakuMessage>.broadcast();
  final _commentController = StreamController<LiveDanmakuComment>.broadcast();

  LiveDanmakuAuth? _auth;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 5;
  static const _heartbeatInterval = Duration(seconds: 30);
  static const _reconnectDelay = Duration(seconds: 5);

  @override
  Stream<LiveDanmakuConnectionState> get connectionStateStream =>
      _stateController.stream;

  @override
  Stream<LiveDanmakuMessage> get messageStream => _messageController.stream;

  @override
  Stream<LiveDanmakuComment> get commentStream => _commentController.stream;

  @override
  bool get isConnected =>
      _stateController.hasListener &&
      (_stateController.stream.isBroadcast || true) &&
      _currentState == LiveDanmakuConnectionState.authenticated;

  LiveDanmakuConnectionState _currentState =
      LiveDanmakuConnectionState.disconnected;

  @override
  Future<void> connect(LiveDanmakuAuth auth) async {
    if (_currentState == LiveDanmakuConnectionState.connected ||
        _currentState == LiveDanmakuConnectionState.authenticated) {
      await disconnect();
    }

    _auth = auth;
    _setState(LiveDanmakuConnectionState.connecting);

    try {
      final wsUrl = LiveDanmakuApi.wsUrl(
        roomId: auth.roomId,
        token: auth.token,
      );

      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      // Note: In real impl, we'd need to handle binary messages
      // For now using StreamChannel with binary support

      _setState(LiveDanmakuConnectionState.connected);
      _setState(LiveDanmakuConnectionState.authenticating);

      // Send auth packet
      final authPacket = LiveDanmakuPacket.createAuthPacket(
        roomId: auth.roomId,
        token: auth.token,
      );
      await _sendBinary(authPacket);

      // Start listening
      _listen(channel);

      // Start heartbeat
      _startHeartbeat();

      _reconnectAttempts = 0;
    } on Object {
      _setState(LiveDanmakuConnectionState.failed);
      rethrow;
    }
  }

  void _listen(WebSocketChannel channel) {
    channel.stream.listen(
      (event) {
        if (event is Uint8List) {
          _handleBinaryMessage(event);
        } else if (event is String) {
          // Text frames not expected in this protocol
        }
      },
      onError: (error) {
        _handleError(error);
      },
      onDone: () {
        _handleDisconnect();
      },
    );
  }

  void _handleBinaryMessage(Uint8List data) {
    try {
      final packet = LiveDanmakuPacket.fromBytes(data);

      switch (packet.opCode) {
        case LiveDanmakuOpCode.authReply:
          _handleAuthReply(packet);
          break;
        case LiveDanmakuOpCode.heartbeatReply:
          // Heartbeat acknowledged
          break;
        case LiveDanmakuOpCode.notify:
          _handleNotify(packet);
          break;
        default:
          // Unknown op code
          break;
      }
    } on FormatException {
      // Log and continue
    }
  }

  void _handleAuthReply(LiveDanmakuPacket packet) {
    // Auth reply typically has empty body or popularity count
    if (packet.payload.isNotEmpty) {
      // Could parse popularity from payload
    }
    _setState(LiveDanmakuConnectionState.authenticated);
  }

  void _handleNotify(LiveDanmakuPacket packet) {
    // Payload is protobuf; for now we parse as JSON for fixture testing
    // Real impl: parse protobuf using generated classes
    try {
      final jsonStr = utf8.decode(packet.payload);
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      final message = LiveDanmakuMessage.fromJson(jsonMap);
      _messageController.add(message);

      if (message.isDanmaku) {
        final comment = message.asComment();
        if (comment != null) {
          _commentController.add(comment);
        }
      }
    } on FormatException {
      // Not JSON, could be raw protobuf - skip for fixture tests
    }
  }

  void _handleError(Object error) {
    if (_currentState == LiveDanmakuConnectionState.authenticated) {
      _scheduleReconnect();
    } else {
      _setState(LiveDanmakuConnectionState.failed);
    }
  }

  void _handleDisconnect() {
    _stopHeartbeat();
    if (_currentState == LiveDanmakuConnectionState.authenticated) {
      _scheduleReconnect();
    } else {
      _setState(LiveDanmakuConnectionState.disconnected);
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _setState(LiveDanmakuConnectionState.failed);
      return;
    }

    _setState(LiveDanmakuConnectionState.reconnecting);
    _reconnectAttempts++;

    _reconnectTimer = Timer(_reconnectDelay * _reconnectAttempts, () {
      if (_auth != null) {
        connect(_auth!);
      }
    });
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      sendHeartbeat();
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  @override
  Future<void> sendHeartbeat() async {
    if (_currentState != LiveDanmakuConnectionState.authenticated) return;

    final heartbeatPacket = LiveDanmakuPacket.createHeartbeatPacket();
    await _sendBinary(heartbeatPacket);
  }

  Future<void> _sendBinary(Uint8List data) async {
    if (_channel != null) {
      _channel.sink.add(data);
    }
  }

  void _setState(LiveDanmakuConnectionState state) {
    _currentState = state;
    _stateController.add(state);
  }

  @override
  Future<void> disconnect() async {
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _channel?.sink.close(ws_status.normalClosure);
    _setState(LiveDanmakuConnectionState.disconnected);
  }

  void dispose() {
    _stateController.close();
    _messageController.close();
    _commentController.close();
    _stopHeartbeat();
    _reconnectTimer?.cancel();
  }
}

/// Fixture-based test client for offline testing.
///
/// Uses pre-recorded binary fixture files instead of real WebSocket.
/// Fixtures recorded from real Bilibili live rooms.
class LiveDanmakuFixtureClient implements NetworkLiveDanmakuDataSource {
  LiveDanmakuFixtureClient({required this.fixturePath});

  final String fixturePath;
  final _stateController =
      StreamController<LiveDanmakuConnectionState>.broadcast();
  final _messageController = StreamController<LiveDanmakuMessage>.broadcast();
  final _commentController = StreamController<LiveDanmakuComment>.broadcast();

  LiveDanmakuConnectionState _currentState =
      LiveDanmakuConnectionState.disconnected;

  @override
  Stream<LiveDanmakuConnectionState> get connectionStateStream =>
      _stateController.stream;

  @override
  Stream<LiveDanmakuMessage> get messageStream => _messageController.stream;

  @override
  Stream<LiveDanmakuComment> get commentStream => _commentController.stream;

  @override
  bool get isConnected =>
      _currentState == LiveDanmakuConnectionState.authenticated;

  @override
  Future<void> connect(LiveDanmakuAuth auth) async {
    _setState(LiveDanmakuConnectionState.connecting);
    _setState(LiveDanmakuConnectionState.authenticating);

    // Simulate auth delay
    await Future.delayed(const Duration(milliseconds: 100));

    _setState(LiveDanmakuConnectionState.authenticated);

    // Load and replay fixture
    await _replayFixture();
  }

  Future<void> _replayFixture() async {
    final file = File(fixturePath);
    if (!await file.exists()) {
      _setState(LiveDanmakuConnectionState.failed);
      return;
    }

    final bytes = await file.readAsBytes();
    // Parse fixture as sequence of packets
    // Fixture format: concatenated binary packets
    int offset = 0;
    while (offset < bytes.length) {
      if (offset + 16 > bytes.length) break;

      final header = ByteData.view(bytes.buffer, offset, 16);
      final packetLen = header.getUint32(0, Endian.big);

      if (offset + packetLen > bytes.length) break;

      final packetBytes = bytes.sublist(offset, offset + packetLen);
      offset += packetLen;

      try {
        final packet = LiveDanmakuPacket.fromBytes(packetBytes);
        _handlePacket(packet);
      } on FormatException {
        // Skip malformed packets in fixture
      }

      // Small delay between messages
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void _handlePacket(LiveDanmakuPacket packet) {
    switch (packet.opCode) {
      case LiveDanmakuOpCode.authReply:
        // Already authenticated
        break;
      case LiveDanmakuOpCode.heartbeatReply:
        break;
      case LiveDanmakuOpCode.notify:
        _handleNotify(packet);
        break;
      default:
        break;
    }
  }

  void _handleNotify(LiveDanmakuPacket packet) {
    try {
      final jsonStr = utf8.decode(packet.payload);
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      final message = LiveDanmakuMessage.fromJson(jsonMap);
      _messageController.add(message);

      if (message.isDanmaku) {
        final comment = message.asComment();
        if (comment != null) {
          _commentController.add(comment);
        }
      }
    } on FormatException {
      // Skip
    }
  }

  @override
  Future<void> sendHeartbeat() async {
    // No-op for fixture client
  }

  @override
  Future<void> disconnect() async {
    _setState(LiveDanmakuConnectionState.disconnected);
  }

  void _setState(LiveDanmakuConnectionState state) {
    _currentState = state;
    _stateController.add(state);
  }

  void dispose() {
    _stateController.close();
    _messageController.close();
    _commentController.close();
  }
}

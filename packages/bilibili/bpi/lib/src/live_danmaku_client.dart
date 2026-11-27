import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'model/live/live_danmaku.dart';
import 'network_live_danmaku_data_source.dart';

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

    // Support both binary and JSON array fixture formats
    List<int> bytes;
    final content = await file.readAsString();
    if (content.trim().startsWith('[')) {
      // JSON array format: [16, 0, 0, 0, ...]
      final jsonList = jsonDecode(content) as List;
      bytes = jsonList.cast<int>();
    } else {
      // Binary format
      bytes = content.codeUnits;
    }

    // Parse fixture as sequence of packets
    // Fixture format: concatenated binary packets
    final uint8Bytes = Uint8List.fromList(bytes);
    int offset = 0;
    while (offset < uint8Bytes.length) {
      if (offset + 16 > uint8Bytes.length) break;

      final header = ByteData.view(uint8Bytes.buffer, offset, 16);
      final packetLen = header.getUint32(0, Endian.big);

      if (offset + packetLen > uint8Bytes.length) break;

      final packetBytes = uint8Bytes.sublist(offset, offset + packetLen);
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

  @override
  List<LiveDanmakuMessage> parseFrames(List<int> bytes) {
    final messages = <LiveDanmakuMessage>[];
    final uint8Bytes = Uint8List.fromList(bytes);
    int offset = 0;
    while (offset < uint8Bytes.length) {
      if (offset + 16 > uint8Bytes.length) break;

      final header = ByteData.view(uint8Bytes.buffer, offset, 16);
      final packetLen = header.getUint32(0, Endian.big);

      if (offset + packetLen > uint8Bytes.length) break;

      final packetBytes = uint8Bytes.sublist(offset, offset + packetLen);
      offset += packetLen;

      try {
        final packet = LiveDanmakuPacket.fromBytes(packetBytes);
        if (packet.opCode == LiveDanmakuOpCode.notify) {
          try {
            final jsonStr = utf8.decode(packet.payload);
            final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
            final message = LiveDanmakuMessage.fromJson(jsonMap);
            messages.add(message);
          } on FormatException {
            // Skip non-JSON payloads
          }
        }
      } on FormatException {
        // Skip malformed packets
      }
    }
    return messages;
  }
}

import 'package:meta/meta.dart';

/// Bilibili live danmaku WebSocket protocol version.
enum LiveDanmakuProtocolVersion {
  v1(1),
  v2(2);

  final int value;
  const LiveDanmakuProtocolVersion(this.value);
}

/// Bilibili live danmaku WebSocket message operation codes.
enum LiveDanmakuOpCode {
  /// Client -> Server: Handshake request (auth)
  handshakeRequest(7),

  /// Server -> Client: Handshake response (auth result)
  handshakeResponse(8),

  /// Client -> Server: Heartbeat
  heartbeat(2),

  /// Server -> Client: Heartbeat response
  heartbeatResponse(3),

  /// Server -> Client: Notification / danmaku message
  notification(5),

  /// Server -> Client: Disconnect / reconnect
  disconnect(6);

  final int value;
  const LiveDanmakuOpCode(this.value);

  static LiveDanmakuOpCode? fromValue(int value) {
    return switch (value) {
      2 => LiveDanmakuOpCode.heartbeat,
      3 => LiveDanmakuOpCode.heartbeatResponse,
      5 => LiveDanmakuOpCode.notification,
      6 => LiveDanmakuOpCode.disconnect,
      7 => LiveDanmakuOpCode.handshakeRequest,
      8 => LiveDanmakuOpCode.handshakeResponse,
      _ => null,
    };
  }
}

/// Bilibili live danmaku WebSocket message types (in notification payload).
enum LiveDanmakuMessageType {
  /// Danmaku message
  danmaku('DANMU_MSG'),

  /// Gift message
  gift('SEND_GIFT'),

  /// Guard buy
  guardBuy('GUARD_BUY'),

  /// Super chat
  superChat('SUPER_CHAT_MESSAGE'),

  /// User entry
  entry('INTERACT_WORD'),

  /// Like / popularity
  like('WATCHED_CHANGE'),

  /// Room state change
  roomChange('ROOM_CHANGE'),

  /// Unknown / other
  unknown('UNKNOWN');

  final String value;
  const LiveDanmakuMessageType(this.value);

  static LiveDanmakuMessageType fromString(String value) {
    return switch (value) {
      'DANMU_MSG' => LiveDanmakuMessageType.danmaku,
      'SEND_GIFT' => LiveDanmakuMessageType.gift,
      'GUARD_BUY' => LiveDanmakuMessageType.guardBuy,
      'SUPER_CHAT_MESSAGE' => LiveDanmakuMessageType.superChat,
      'INTERACT_WORD' => LiveDanmakuMessageType.entry,
      'WATCHED_CHANGE' => LiveDanmakuMessageType.like,
      'ROOM_CHANGE' => LiveDanmakuMessageType.roomChange,
      _ => LiveDanmakuMessageType.unknown,
    };
  }
}

/// Bilibili live danmaku message mode (in danmaku payload).
enum LiveDanmakuMode {
  /// Scrolling (right to left)
  scrolling(1),

  /// Top fixed
  top(4),

  /// Bottom fixed
  bottom(5),

  /// Reverse (left to right)
  reverse(6),

  /// Special (advanced)
  special(7);

  final int value;
  const LiveDanmakuMode(this.value);

  static LiveDanmakuMode fromValue(int value) {
    return switch (value) {
      1 => LiveDanmakuMode.scrolling,
      4 => LiveDanmakuMode.top,
      5 => LiveDanmakuMode.bottom,
      6 => LiveDanmakuMode.reverse,
      7 => LiveDanmakuMode.special,
      _ => LiveDanmakuMode.scrolling,
    };
  }
}

/// Bilibili live danmaku WebSocket message frame.
///
/// Wire format (protobuf-like):
/// - 4 bytes: packet length (big endian, includes header)
/// - 2 bytes: header length (always 16)
/// - 2 bytes: protocol version (1 or 2)
/// - 4 bytes: operation code
/// - 4 bytes: sequence id
/// - body: variable length
@immutable
final class LiveDanmakuFrame {
  const LiveDanmakuFrame({
    required this.opCode,
    required this.body,
    this.protocolVersion = LiveDanmakuProtocolVersion.v1,
    this.sequenceId = 1,
  });

  final LiveDanmakuProtocolVersion protocolVersion;
  final LiveDanmakuOpCode opCode;
  final int sequenceId;
  final List<int> body;

  /// Total packet length including header (16 bytes)
  int get packetLength => 16 + body.length;

  /// Encode frame to bytes
  List<int> encode() {
    final bytes = <int>[];
    // Packet length (4 bytes, big endian)
    bytes.addAll(_int32ToBytes(packetLength));
    // Header length (2 bytes, big endian) - always 16
    bytes.addAll(_int16ToBytes(16));
    // Protocol version (2 bytes, big endian)
    bytes.addAll(_int16ToBytes(protocolVersion.value));
    // Operation code (4 bytes, big endian)
    bytes.addAll(_int32ToBytes(opCode.value));
    // Sequence ID (4 bytes, big endian)
    bytes.addAll(_int32ToBytes(sequenceId));
    // Body
    bytes.addAll(body);
    return bytes;
  }

  /// Decode frame from bytes
  static LiveDanmakuFrame decode(List<int> bytes) {
    if (bytes.length < 16) {
      throw const FormatException('Frame too short');
    }
    final packetLength = _bytesToInt32(bytes, 0);
    final headerLength = _bytesToInt16(bytes, 4);
    final protocolVersion = _bytesToInt16(bytes, 6);
    final opCode = _bytesToInt32(bytes, 8);
    final sequenceId = _bytesToInt32(bytes, 12);

    if (headerLength != 16) {
      throw FormatException('Invalid header length: $headerLength');
    }
    if (bytes.length < packetLength) {
      throw const FormatException('Incomplete frame');
    }

    final body = bytes.sublist(16, packetLength);
    return LiveDanmakuFrame(
      protocolVersion: LiveDanmakuProtocolVersion.values.firstWhere(
        (v) => v.value == protocolVersion,
        orElse: () => LiveDanmakuProtocolVersion.v1,
      ),
      opCode:
          LiveDanmakuOpCode.fromValue(opCode) ?? LiveDanmakuOpCode.notification,
      sequenceId: sequenceId,
      body: body,
    );
  }

  static List<int> _int32ToBytes(int value) {
    return [
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }

  static List<int> _int16ToBytes(int value) {
    return [(value >> 8) & 0xFF, value & 0xFF];
  }

  static int _bytesToInt32(List<int> bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  static int _bytesToInt16(List<int> bytes, int offset) {
    return (bytes[offset] << 8) | bytes[offset + 1];
  }
}

/// Handshake request payload (sent after connection).
@immutable
final class LiveDanmakuHandshakeRequest {
  const LiveDanmakuHandshakeRequest({
    required this.roomId,
    required this.uid,
    required this.token,
    this.protocolVersion = LiveDanmakuProtocolVersion.v2,
    this.platform = 'web',
    this.type = 2,
  });

  final int roomId;
  final int uid;
  final String token;
  final LiveDanmakuProtocolVersion protocolVersion;
  final String platform;
  final int type;

  Map<String, dynamic> toJson() => {
    'roomid': roomId,
    'uid': uid,
    'protover': protocolVersion.value,
    'platform': platform,
    'type': type,
    'key': token,
  };
}

/// Handshake response payload.
@immutable
final class LiveDanmakuHandshakeResponse {
  const LiveDanmakuHandshakeResponse({required this.code, this.message});

  final int code;
  final String? message;

  bool get isSuccess => code == 0;

  factory LiveDanmakuHandshakeResponse.fromJson(Map<String, dynamic> json) {
    return LiveDanmakuHandshakeResponse(
      code: json['code'] as int? ?? -1,
      message: json['msg'] as String?,
    );
  }
}

/// Parsed danmaku message from notification.
@immutable
final class LiveDanmakuMessage {
  const LiveDanmakuMessage({
    required this.type,
    required this.payload,
    this.rawType,
  });

  final LiveDanmakuMessageType type;
  final Map<String, dynamic> payload;
  final String? rawType;

  /// Extract danmaku comment if this is a danmaku message
  LiveDanmakuComment? get comment {
    if (type != LiveDanmakuMessageType.danmaku) return null;
    try {
      final info = payload['info'] as List<dynamic>?;
      if (info == null || info.length < 4) return null;

      final content = info[1] as String? ?? '';
      final mode = info[0] as List<dynamic>? ?? [];
      final modeValue = mode.length > 1 ? mode[1] as int? ?? 1 : 1;
      final fontSize = (mode.length > 2 ? mode[2] : null) as int? ?? 25;
      final color = (mode.length > 3 ? mode[3] : null) as int? ?? 0xFFFFFF;
      final timestamp = info[3] as List<dynamic>? ?? [];
      final startSeconds = timestamp.isNotEmpty
          ? (timestamp[0] as num).toDouble()
          : 0.0;

      return LiveDanmakuComment(
        content: content,
        mode: LiveDanmakuMode.fromValue(modeValue),
        fontSize: fontSize.toDouble(),
        colorArgb: 0xFF000000 | color,
        startTime: Duration(milliseconds: (startSeconds * 1000).round()),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Neutral danmaku comment for upper layers.
@immutable
final class LiveDanmakuComment {
  const LiveDanmakuComment({
    required this.content,
    required this.mode,
    required this.fontSize,
    required this.colorArgb,
    required this.startTime,
    this.userName,
    this.userId,
    this.isAdmin = false,
    this.isVip = false,
    this.medalName,
    this.medalLevel,
  });

  final String content;
  final LiveDanmakuMode mode;
  final double fontSize;
  final int colorArgb;
  final Duration startTime;
  final String? userName;
  final int? userId;
  final bool isAdmin;
  final bool isVip;
  final String? medalName;
  final int? medalLevel;
}

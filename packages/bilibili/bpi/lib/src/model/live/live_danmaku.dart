import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'network_live_room_detail.dart';

/// Bilibili live danmaku WebSocket message types (operation codes).
///
/// Based on observed protocol: protobuf over WebSocket with zlib/brotli compression.
/// See https://github.com/SocialSisterYi/bilibili-API-collect/blob/master/docs/live/danmaku.md
enum LiveDanmakuOpCode {
  // Server -> Client
  heartbeatReply(3), // 心跳回复
  notify(5), // 通知消息（弹幕、礼物、进入等）
  authReply(7), // 鉴权回复

  // Client -> Server
  auth(7), // 鉴权/握手
  heartbeat(2), // 心跳

  // Internal
  unknown(-1);

  const LiveDanmakuOpCode(this.value);
  final int value;

  static LiveDanmakuOpCode fromValue(int value) {
    return LiveDanmakuOpCode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LiveDanmakuOpCode.unknown,
    );
  }
}

/// Live danmaku message header (protobuf wrapper structure).
///
/// Actual payload is compressed protobuf. This represents the decoded envelope.
@immutable
final class LiveDanmakuPacket {
  const LiveDanmakuPacket({
    required this.opCode,
    required this.payload,
    this.rawPayload,
  });

  final LiveDanmakuOpCode opCode;
  final Uint8List payload;
  final Uint8List? rawPayload; // For fixture recording

  factory LiveDanmakuPacket.fromBytes(Uint8List bytes) {
    // Protocol: 16-byte header + compressed body
    // Header: packet_len(4) + header_len(2) + ver(2) + op(4) + seq(4)
    if (bytes.length < 16) {
      throw const FormatException('Packet too short for header');
    }
    final header = bytes.buffer.asByteData();
    final packetLen = header.getUint32(0, Endian.big);
    final headerLen = header.getUint16(4, Endian.big);
    final ver = header.getUint16(6, Endian.big);
    final op = header.getUint32(8, Endian.big);
    // seq = header.getUint32(12, Endian.big);

    if (bytes.length != packetLen) {
      throw FormatException(
        'Packet length mismatch: expected $packetLen, got ${bytes.length}',
      );
    }

    final body = bytes.sublist(headerLen);

    // Decompress based on version
    // ver=0: raw; ver=1: heartbeat (no body); ver=2: zlib; ver=3: brotli
    Uint8List decompressed;
    switch (ver) {
      case 0:
        decompressed = body;
        break;
      case 1:
        // Heartbeat reply typically has no body or just popularity count
        decompressed = body;
        break;
      case 2:
        decompressed = Uint8List.fromList(ZLibCodec().decode(body));
        break;
      case 3:
        decompressed = _decodeBrotli(body);
        break;
      default:
        decompressed = body;
    }

    return LiveDanmakuPacket(
      opCode: LiveDanmakuOpCode.fromValue(op),
      payload: decompressed,
      rawPayload: bytes,
    );
  }

  static Uint8List _decodeBrotli(Uint8List data) {
    // Brotli decoding - placeholder, actual implementation needs brotli package
    // For now return as-is; fixture tests will use pre-decompressed data
    return data;
  }

  /// Create auth packet (client -> server)
  static Uint8List createAuthPacket({
    required int roomId,
    required String token,
    int protocol = 1,
    String platform = 'web',
  }) {
    // Protobuf: Auth { roomid, token, protover, platform, type }
    // Simplified: JSON-like structure for now, real impl uses protobuf
    final authJson = {
      'roomid': roomId,
      'token': token,
      'protover': protocol,
      'platform': platform,
      'type': 2, // 2 = websocket
    };
    final jsonBytes = utf8.encode(jsonEncode(authJson));
    return _wrapPacket(jsonBytes, opCode: LiveDanmakuOpCode.auth.value, ver: 0);
  }

  /// Create heartbeat packet (client -> server)
  static Uint8List createHeartbeatPacket() {
    // Heartbeat body: empty or popularity int
    return _wrapPacket(
      Uint8List(0),
      opCode: LiveDanmakuOpCode.heartbeat.value,
      ver: 1,
    );
  }

  static Uint8List _wrapPacket(
    Uint8List body, {
    required int opCode,
    int ver = 0,
  }) {
    final headerLen = 16;
    final packetLen = headerLen + body.length;
    final buffer = ByteData(packetLen);
    buffer.setUint32(0, packetLen, Endian.big);
    buffer.setUint16(4, headerLen, Endian.big);
    buffer.setUint16(6, ver, Endian.big);
    buffer.setUint32(8, opCode, Endian.big);
    buffer.setUint32(12, 0, Endian.big); // seq
    final result = Uint8List(packetLen);
    result.setRange(0, headerLen, buffer.buffer.asUint8List());
    result.setRange(headerLen, packetLen, body);
    return result;
  }
}

/// Parsed live danmaku message from notify (op=5) payload.
@immutable
final class LiveDanmakuMessage {
  const LiveDanmakuMessage({
    required this.cmd,
    required this.data,
    this.rawData,
  });

  /// Command type: DANMU_MSG, SEND_GIFT, GUARD_BUY, SUPER_CHAT_MESSAGE, etc.
  final String cmd;

  /// Parsed message data (protobuf decoded to JSON-like map)
  final Map<String, dynamic> data;

  /// Raw protobuf bytes for fixture recording
  final Uint8List? rawData;

  /// Whether this is a user comment (danmaku)
  bool get isDanmaku => cmd == 'DANMU_MSG';

  /// Whether this is a gift message
  bool get isGift => cmd == 'SEND_GIFT';

  /// Whether this is a guard buy
  bool get isGuardBuy => cmd == 'GUARD_BUY';

  /// Whether this is a super chat
  bool get isSuperChat => cmd == 'SUPER_CHAT_MESSAGE';

  /// Whether this is a user entering
  bool get isEntry => cmd == 'ENTRY_EFFECT' || cmd == 'INTERACT_WORD';

  factory LiveDanmakuMessage.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return LiveDanmakuMessage(
      cmd: json['cmd'] as String? ?? 'UNKNOWN',
      data: data is Map<String, dynamic> ? data : <String, dynamic>{},
      rawData: null,
    );
  }

  /// Extract danmaku comment if this is a DANMU_MSG
  LiveDanmakuComment? asComment() {
    if (!isDanmaku) return null;
    return LiveDanmakuComment.fromData(data);
  }
}

/// Parsed danmaku comment from DANMU_MSG.
@immutable
final class LiveDanmakuComment {
  const LiveDanmakuComment({
    required this.content,
    required this.userId,
    required this.username,
    required this.userFace,
    required this.medalName,
    required this.medalLevel,
    required this.guardLevel,
    required this.userLevel,
    required this.timestamp,
    this.rawData,
  });

  final String content;
  final int userId;
  final String username;
  final String userFace;
  final String? medalName;
  final int? medalLevel;
  final int guardLevel;
  final int userLevel;
  final int timestamp;
  final Uint8List? rawData;

  factory LiveDanmakuComment.fromData(Map<String, dynamic> data) {
    final info = data['info'];
    final infoList = info is List ? info.cast<dynamic>() : <dynamic>[];
    // info[0] = [mode, fontsize, color, timestamp, rnd, ...]
    // info[1] = content
    // info[2] = [uid, username, is_admin, is_vip, ...]
    // info[3] = medal info or null
    // info[4] = user level info
    final baseInfo = infoList.isNotEmpty && infoList[0] is List
        ? (infoList[0] as List).cast<dynamic>()
        : <dynamic>[];
    final userInfo = infoList.length > 2 && infoList[2] is List
        ? (infoList[2] as List).cast<dynamic>()
        : <dynamic>[];
    final medalInfo = infoList.length > 3 && infoList[3] is List
        ? (infoList[3] as List).cast<dynamic>()
        : null;
    final levelInfo = infoList.length > 4 && infoList[4] is List
        ? (infoList[4] as List).cast<dynamic>()
        : <dynamic>[];

    return LiveDanmakuComment(
      content: infoList.length > 1 && infoList[1] is String
          ? infoList[1] as String
          : '',
      userId: userInfo.isNotEmpty && userInfo[0] is int
          ? userInfo[0] as int
          : 0,
      username: userInfo.length > 1 && userInfo[1] is String
          ? userInfo[1] as String
          : '',
      userFace: userInfo.length > 9 && userInfo[9] is String
          ? userInfo[9] as String
          : '',
      medalName:
          medalInfo != null && medalInfo.length > 1 && medalInfo[1] is String
          ? medalInfo[1] as String
          : null,
      medalLevel:
          medalInfo != null && medalInfo.isNotEmpty && medalInfo[0] is int
          ? medalInfo[0] as int
          : null,
      guardLevel: userInfo.length > 7 && userInfo[7] is int
          ? userInfo[7] as int
          : 0,
      userLevel: levelInfo.isNotEmpty && levelInfo[0] is int
          ? levelInfo[0] as int
          : 0,
      timestamp: baseInfo.length > 3 && baseInfo[3] is int
          ? baseInfo[3] as int
          : 0,
      rawData: null,
    );
  }
}

/// Live danmaku authentication info from room detail.
@immutable
final class LiveDanmakuAuth {
  const LiveDanmakuAuth({
    required this.roomId,
    required this.token,
    required this.hostList,
    this.refreshInterval = 30,
  });

  final int roomId;
  final String token;
  final List<String> hostList;
  final int refreshInterval; // seconds

  factory LiveDanmakuAuth.fromRoomDetail(NetworkLiveRoomDetail detail) {
    // Extract danmaku connection info from live room detail
    // The actual token comes from a separate API or embedded in room detail
    return LiveDanmakuAuth(
      roomId: detail.roomInfo?.roomId ?? 0,
      token: detail.danmakuToken ?? '',
      hostList: detail.danmakuHosts ?? ['broadcastlv.chat.bilibili.com'],
      refreshInterval: 30,
    );
  }
}

/// Extension to add danmaku fields to NetworkLiveRoomDetail
extension LiveRoomDetailDanmakuExt on NetworkLiveRoomDetail {
  String? get danmakuToken => null; // To be populated from actual API
  List<String>? get danmakuHosts => null;
}

/// B站直播弹幕 WebSocket 应用层协议包操作码（op 字段取值）。
enum WsOperation {
  heartbeat(2),
  heartbeatReply(3),
  message(5),
  auth(7),
  authReply(8);

  const WsOperation(this.code);
  final int code;
}

/// 16 字节包头 + 可选包体的直播弹幕协议包。
///
/// 包头布局（全部大端）：
/// - packetLen：UInt32，整个包长度（含包头）
/// - headerLen：UInt16，包头长度（固定 16）
/// - protocolVersion：UInt16，0=原始 / 1=protobuf / 2=zlib 压缩
/// - operation：UInt32，操作码（见 [WsOperation]）
/// - sequence：UInt32，序列号
class WsPacket {
  const WsPacket({
    required this.packetLen,
    required this.headerLen,
    required this.protocolVersion,
    required this.operation,
    required this.sequence,
    this.body = const [],
  });

  final int packetLen;
  final int headerLen;
  final int protocolVersion;
  final int operation;
  final int sequence;
  final List<int> body;

  factory WsPacket.decode(List<int> bytes) {
    if (bytes.length < 16) {
      throw const FormatException('WsPacket: 字节不足 16');
    }
    final packetLen = _readU32(bytes, 0);
    final headerLen = _readU16(bytes, 4);
    final end = bytes.length < packetLen ? bytes.length : packetLen;
    return WsPacket(
      packetLen: packetLen,
      headerLen: headerLen,
      protocolVersion: _readU16(bytes, 6),
      operation: _readU32(bytes, 8),
      sequence: _readU32(bytes, 12),
      body: bytes.length > headerLen ? bytes.sublist(headerLen, end) : const [],
    );
  }

  List<int> encode() {
    return [
      ..._writeU32(16 + body.length),
      ..._writeU16(headerLen),
      ..._writeU16(protocolVersion),
      ..._writeU32(operation),
      ..._writeU32(sequence),
      ...body,
    ];
  }

  /// 从字节流切出第一个完整包，返回（包, 剩余字节）。
  ///
  /// 剩余字节可能包含后续包或不完整包的开头。
  static (WsPacket, List<int>) split(List<int> bytes) {
    if (bytes.length < 16) {
      throw const FormatException('WsPacket: 字节不足 16');
    }
    final packetLen = _readU32(bytes, 0);
    if (packetLen > bytes.length) {
      throw const FormatException('WsPacket: 包不完整');
    }
    return (
      WsPacket.decode(bytes.sublist(0, packetLen)),
      bytes.sublist(packetLen),
    );
  }

  static List<int> _writeU32(int value) => [
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  ];

  static List<int> _writeU16(int value) => [(value >> 8) & 0xFF, value & 0xFF];

  static int _readU32(List<int> b, int o) =>
      ((b[o] & 0xFF) << 24) |
      ((b[o + 1] & 0xFF) << 16) |
      ((b[o + 2] & 0xFF) << 8) |
      (b[o + 3] & 0xFF);

  static int _readU16(List<int> b, int o) =>
      ((b[o] & 0xFF) << 8) | (b[o + 1] & 0xFF);
}

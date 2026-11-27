import '../utils/bounded_zlib.dart';
import 'danmaku_message.dart';
import 'packet.dart';

/// Bounded decoder for the live danmaku frame stream.
///
/// The stream can contain zlib-compressed packets whose bodies hold more
/// packets, so both the buffered byte count and the compression nesting depth
/// are capped. Input beyond either cap is dropped instead of allocated, which
/// keeps a crafted frame from exhausting memory or the call stack.
class DanmakuFrameDecoder({
  final int maxBuffer = 64 * 1024,
  final int maxDepth = 3,
}) {
  List<int> _buffer = [];

  /// Feeds [data] into the decoder and returns the messages it completes.
  List<DanmakuMessage> add(List<int> data) {
    final messages = <DanmakuMessage>[];
    if (data.length > maxBuffer || _buffer.length + data.length > maxBuffer) {
      _buffer = [];
      return messages;
    }
    _buffer.addAll(data);
    _buffer = _drain(_buffer, 0, messages);
    return messages;
  }

  /// Drops any partially buffered frame.
  void reset() => _buffer = [];

  /// Parses complete packets from [buffer] and returns the unconsumed bytes.
  ///
  /// Only the top-level input keeps a remainder across calls. A decompressed
  /// body is parsed from its own local buffer, so sibling packets from the
  /// outer stream never inherit the compressed packet's depth.
  List<int> _drain(List<int> buffer, int depth, List<DanmakuMessage> messages) {
    while (true) {
      if (buffer.length < 16) return buffer;
      final packetLen = _readU32(buffer, 0);
      // A bad length would otherwise pin every later frame behind it.
      if (packetLen < 16 || packetLen > maxBuffer) return [];
      if (packetLen > buffer.length) return buffer;
      final (packet, rest) = WsPacket.split(buffer);
      buffer = rest;
      _handlePacket(packet, depth, messages);
    }
  }

  void _handlePacket(
    WsPacket packet,
    int depth,
    List<DanmakuMessage> messages,
  ) {
    if (packet.protocolVersion == 2) {
      if (depth >= maxDepth) return;
      final decompressed = _decompress(packet.body);
      if (decompressed.isNotEmpty) {
        _drain(decompressed, depth + 1, messages);
      }
      return;
    }
    if (packet.operation != WsOperation.message.code) return;
    final message = DanmakuMessage.parse(packet.body);
    if (message != null) messages.add(message);
  }

  List<int> _decompress(List<int> body) {
    try {
      return BoundedZlib.decode(body, maxBytes: maxBuffer);
    } on Object {
      return const [];
    }
  }

  int _readU32(List<int> bytes, int offset) =>
      ((bytes[offset] & 0xFF) << 24) |
      ((bytes[offset + 1] & 0xFF) << 16) |
      ((bytes[offset + 2] & 0xFF) << 8) |
      (bytes[offset + 3] & 0xFF);
}

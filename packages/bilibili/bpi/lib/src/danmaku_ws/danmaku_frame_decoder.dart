import 'dart:io';

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
      final WsPacket packet;
      final List<int> rest;
      try {
        (packet, rest) = WsPacket.split(buffer);
      } on FormatException {
        return buffer;
      }
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
    final sink = _BoundedByteSink(maxBuffer);
    try {
      final decoder = ZLibDecoder().startChunkedConversion(sink);
      decoder.add(body);
      decoder.close();
    } on Object {
      return const [];
    }
    return sink.bytes;
  }
}

/// Collects decompressed bytes but aborts the decoder once its limit is
/// exceeded, so a compression bomb never materialises in memory.
class _BoundedByteSink(final int _maxBytes) implements Sink<List<int>> {
  final List<int> _bytes = [];

  List<int> get bytes => _bytes;

  @override
  void add(List<int> data) {
    if (_bytes.length + data.length > _maxBytes) {
      throw const _FrameTooLarge();
    }
    _bytes.addAll(data);
  }

  @override
  void close() {}
}

class const _FrameTooLarge() implements Exception;

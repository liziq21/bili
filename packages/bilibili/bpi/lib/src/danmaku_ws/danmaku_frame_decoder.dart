import 'dart:io';

import 'danmaku_message.dart';
import 'packet.dart';

/// Bounded decoder for the live danmaku frame stream.
///
/// The stream can contain zlib-compressed packets whose bodies hold more
/// packets, so both the buffered byte count and the compression nesting depth
/// are capped. Input beyond either cap is dropped instead of allocated, which
/// keeps a crafted frame from exhausting memory or the call stack.
class DanmakuFrameDecoder {
  DanmakuFrameDecoder({this.maxBuffer = 64 * 1024, this.maxDepth = 3});

  final int maxBuffer;
  final int maxDepth;

  List<int> _buffer = [];

  /// Feeds [data] into the decoder and returns the messages it completes.
  List<DanmakuMessage> add(List<int> data) {
    final messages = <DanmakuMessage>[];
    _feed(data, 0, messages);
    return messages;
  }

  /// Drops any partially buffered frame.
  void reset() => _buffer = [];

  void _feed(List<int> data, int depth, List<DanmakuMessage> messages) {
    if (depth > maxDepth) return;
    if (data.length > maxBuffer || _buffer.length + data.length > maxBuffer) {
      _buffer = [];
      return;
    }
    _buffer.addAll(data);
    while (true) {
      try {
        final (packet, rest) = WsPacket.split(_buffer);
        _buffer = rest;
        _handlePacket(packet, depth, messages);
      } on FormatException {
        break;
      }
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
        _feed(decompressed, depth + 1, messages);
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
class _BoundedByteSink implements Sink<List<int>> {
  _BoundedByteSink(this._maxBytes);

  final int _maxBytes;
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

class _FrameTooLarge implements Exception {
  const _FrameTooLarge();
}

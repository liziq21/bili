import 'dart:io';

/// Zlib decoding with a hard cap on the decompressed output.
abstract final class BoundedZlib {
  static const int defaultMaxBytes = 64 * 1024;

  /// Decompresses [body], aborting before the output exceeds [maxBytes].
  ///
  /// Throws [FormatException] when the payload is corrupt or larger than the
  /// cap, so a compression bomb is never materialised in memory.
  static List<int> decode(List<int> body, {int maxBytes = defaultMaxBytes}) {
    final sink = _BoundedByteSink(maxBytes);
    try {
      final decoder = ZLibDecoder().startChunkedConversion(sink);
      decoder.add(body);
      decoder.close();
    } on _ZlibOutputTooLarge {
      throw const FormatException('zlib payload exceeds the size limit');
    }
    return sink.bytes;
  }
}

class _BoundedByteSink(final int _maxBytes) implements Sink<List<int>> {
  final List<int> _bytes = [];

  List<int> get bytes => _bytes;

  @override
  void add(List<int> data) {
    if (_bytes.length + data.length > _maxBytes) {
      throw const _ZlibOutputTooLarge();
    }
    _bytes.addAll(data);
  }

  @override
  void close() {}
}

class const _ZlibOutputTooLarge() implements Exception;

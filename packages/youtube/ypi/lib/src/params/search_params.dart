import 'dart:convert';

/// Encodes the opaque InnerTube `params` filter string for `/v1/search`.
///
/// The value is a base64-encoded protobuf message: varint field 2 carries the
/// sort order and length-delimited field 8 carries a filter submessage whose
/// varint fields are the upload date (1), content type (2), duration (3) and
/// one field per enabled feature (using YouTube's own field tags). Callers
/// translate their own filter model into these raw values; this package never
/// depends on the caller's model.
abstract final class YoutubeSearchParams {
  /// Content type values: video (1), channel (2), playlist (3).
  static String encode({
    int? sort,
    int? uploadDate,
    int? contentType,
    int? duration,
    Set<int> features = const {},
  }) {
    final rootBuffer = <int>[];

    if (sort != null && sort != 0) {
      _writeVarintField(rootBuffer, 2, sort);
    }

    final filterBuffer = <int>[];
    if (uploadDate != null) {
      _writeVarintField(filterBuffer, 1, uploadDate);
    }
    if (contentType != null) {
      _writeVarintField(filterBuffer, 2, contentType);
    }
    if (duration != null) {
      _writeVarintField(filterBuffer, 3, duration);
    }
    for (final featureFieldTag in features) {
      _writeVarintField(filterBuffer, featureFieldTag, 1);
    }

    if (filterBuffer.isNotEmpty) {
      _writeSubmessageField(rootBuffer, 8, filterBuffer);
    }

    if (rootBuffer.isEmpty) {
      return '';
    }

    return base64.encode(rootBuffer);
  }

  static void _writeVarint(List<int> buffer, int value) {
    var v = value;
    while (v >= 0x80) {
      buffer.add((v & 0x7F) | 0x80);
      v >>= 7;
    }
    buffer.add(v & 0x7F);
  }

  static void _writeTag(List<int> buffer, int fieldNumber, int wireType) {
    _writeVarint(buffer, (fieldNumber << 3) | wireType);
  }

  static void _writeVarintField(List<int> buffer, int fieldNumber, int value) {
    _writeTag(buffer, fieldNumber, 0); // WireType 0 = Varint
    _writeVarint(buffer, value);
  }

  static void _writeSubmessageField(
    List<int> buffer,
    int fieldNumber,
    List<int> submessageBytes,
  ) {
    _writeTag(buffer, fieldNumber, 2); // WireType 2 = Length-delimited
    _writeVarint(buffer, submessageBytes.length);
    buffer.addAll(submessageBytes);
  }
}

import 'dart:convert';

import '../model/yt_search_filter.dart';
import '../model/yt_search_sort.dart';

abstract final class YoutubeProtobufEncoder {
  static String encodeSearchParams({
    YoutubeSearchSort sort = YoutubeSearchSort.relevance,
    YoutubeUploadDateFilter? uploadDate,
    YoutubeContentTypeFilter? contentType,
    YoutubeDurationFilter? duration,
    Set<YoutubeFeatureFilter> features = const {},
  }) {
    final rootBuffer = <int>[];

    // Field 2: Sort (Varint)
    if (sort != YoutubeSearchSort.relevance) {
      _writeVarintField(rootBuffer, 2, sort.value);
    }

    // Field 8: Filter options submessage
    final filterBuffer = <int>[];
    if (uploadDate != null) {
      _writeVarintField(filterBuffer, 1, uploadDate.value);
    }
    if (contentType != null) {
      _writeVarintField(filterBuffer, 2, contentType.value);
    }
    if (duration != null) {
      _writeVarintField(filterBuffer, 3, duration.value);
    }
    for (final feature in features) {
      _writeVarintField(filterBuffer, feature.fieldTag, 1);
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

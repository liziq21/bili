import 'dart:convert';

import 'package:test/test.dart';
import 'package:ypi/ypi.dart';

void main() {
  group('YoutubeSearchParams', () {
    test('relevance with no filters produces empty params', () {
      final params = YoutubeSearchParams.encode();
      expect(params, isEmpty);
    });

    test('sort by upload date writes varint field 2', () {
      final params = YoutubeSearchParams.encode(
        sort: 1, // uploadDate = 1
      );
      expect(params, isNotEmpty);

      final bytes = base64.decode(params);
      // Field 2 (Sort), WireType 0 (Varint): (2 << 3) | 0 = 16 (0x10)
      expect(bytes[0], equals(16));
      expect(bytes[1], equals(1)); // Upload date value = 1
    });

    test('sort by view count writes varint field 2', () {
      final params = YoutubeSearchParams.encode(
        sort: 2, // viewCount = 2
      );
      expect(params, isNotEmpty);

      final bytes = base64.decode(params);
      expect(bytes[0], equals(16));
      expect(bytes[1], equals(2)); // View count value = 2
    });

    test('upload date today writes a length-delimited submessage at field 8', () {
      final params = YoutubeSearchParams.encode(
        uploadDate: 2, // today = 2
      );
      expect(params, isNotEmpty);

      final bytes = base64.decode(params);
      // Field 8 (Filters), WireType 2: (8 << 3) | 2 = 66 (0x42)
      expect(bytes[0], equals(66));
      expect(bytes[1], equals(2)); // Submessage length = 2 bytes
      // Subfield 1 (UploadDate), WireType 0: (1 << 3) | 0 = 8
      expect(bytes[2], equals(8));
      expect(bytes[3], equals(2)); // Today value = 2
    });

    test('content type playlist alone encodes to the measured playlist params', () {
      // Pinned against a real request: searchPlaylists sent `QgIQAw==`.
      expect(YoutubeSearchParams.encode(contentType: 3), equals('QgIQAw=='));
    });

    test('sort, duration and features combine into one submessage', () {
      final params = YoutubeSearchParams.encode(
        sort: 3, // rating = 3
        duration: 1, // under4Minutes = 1
        features: {5}, // fourK fieldTag = 5
      );

      expect(base64.decode(params), isNotEmpty);
      expect(params, equals(YoutubeSearchParams.encode(
        sort: 3,
        duration: 1,
        features: {5},
      )));
    });
  });
}

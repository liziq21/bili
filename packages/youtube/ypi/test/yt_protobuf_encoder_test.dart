import 'dart:convert';

import 'package:test/test.dart';

import 'package:ypi/src/protobuf/params_builder.dart';
import 'package:ypi/src/protobuf/yt_protobuf_encoder.dart';

void main() {
  group('YoutubeProtobufEncoder Tests', () {
    test('Default relevance with no filters produces empty params', () {
      final params = YoutubeProtobufEncoder.encodeSearchParams();
      expect(params, isEmpty);
    });

    test('Sort by upload date generates valid Protobuf Base64', () {
      final params = YoutubeProtobufEncoder.encodeSearchParams(
        sort: 1, // uploadDate = 1
      );
      expect(params, isNotEmpty);

      final bytes = base64.decode(params);
      // Field 2 (Sort), WireType 0 (Varint): (2 << 3) | 0 = 16 (0x10)
      expect(bytes[0], equals(16));
      expect(bytes[1], equals(1)); // Upload date value = 1
    });

    test('Sort by view count generates valid Protobuf Base64', () {
      final params = YoutubeProtobufEncoder.encodeSearchParams(
        sort: 2, // viewCount = 2
      );
      expect(params, isNotEmpty);

      final bytes = base64.decode(params);
      expect(bytes[0], equals(16));
      expect(bytes[1], equals(2)); // View count value = 2
    });

    test('Single filter (UploadDate: Today) produces length-delimited submessage at field 8', () {
      final params = YoutubeProtobufEncoder.encodeSearchParams(
        uploadDate: 2, // today = 2
      );
      expect(params, isNotEmpty);

      final bytes = base64.decode(params);
      // Field 8 (Filters), WireType 2 (Length-delimited): (8 << 3) | 2 = 66 (0x42)
      expect(bytes[0], equals(66));
      expect(bytes[1], equals(2)); // Submessage length = 2 bytes
      // Subfield 1 (UploadDate), WireType 0: (1 << 3) | 0 = 8
      expect(bytes[2], equals(8));
      expect(bytes[3], equals(2)); // Today value = 2
    });

    test('YoutubeParamsBuilder fluent API builds identical params', () {
      final builderParams = YoutubeParamsBuilder()
          .setSort(3) // rating = 3
          .setDuration(1) // under4Minutes = 1
          .addFeature(5) // fourK fieldTag = 5
          .build();

      final directParams = YoutubeProtobufEncoder.encodeSearchParams(
        sort: 3,
        duration: 1,
        features: {5},
      );

      expect(builderParams, equals(directParams));
    });
  });
}

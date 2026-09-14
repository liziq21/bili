import 'dart:convert';

import 'package:test/test.dart';
import 'package:ypi/ypi.dart';

void main() {
  group('YoutubeProtobufEncoder Tests', () {
    test('Default relevance with no filters produces empty params', () {
      final params = YoutubeProtobufEncoder.encodeSearchParams();
      expect(params, isEmpty);
    });

    test('Sort by upload date generates valid Protobuf Base64', () {
      final params = YoutubeProtobufEncoder.encodeSearchParams(
        sort: YoutubeSearchSort.uploadDate,
      );
      expect(params, isNotEmpty);

      final bytes = base64.decode(params);
      // Field 2 (Sort), WireType 0 (Varint): (2 << 3) | 0 = 16 (0x10)
      expect(bytes[0], equals(16));
      expect(bytes[1], equals(1)); // Upload date value = 1
    });

    test('Sort by view count generates valid Protobuf Base64', () {
      final params = YoutubeProtobufEncoder.encodeSearchParams(
        sort: YoutubeSearchSort.viewCount,
      );
      expect(params, isNotEmpty);

      final bytes = base64.decode(params);
      expect(bytes[0], equals(16));
      expect(bytes[1], equals(2)); // View count value = 2
    });

    test('Single filter (UploadDate: Today) produces length-delimited submessage at field 8', () {
      final params = YoutubeProtobufEncoder.encodeSearchParams(
        uploadDate: YoutubeUploadDateFilter.today,
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
          .setSort(YoutubeSearchSort.rating)
          .setDuration(YoutubeDurationFilter.under4Minutes)
          .addFeature(YoutubeFeatureFilter.fourK)
          .build();

      final directParams = YoutubeProtobufEncoder.encodeSearchParams(
        sort: YoutubeSearchSort.rating,
        duration: YoutubeDurationFilter.under4Minutes,
        features: {YoutubeFeatureFilter.fourK},
      );

      expect(builderParams, equals(directParams));
    });
  });
}

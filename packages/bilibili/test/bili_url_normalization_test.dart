import 'dart:convert';
import 'dart:io';

import 'package:bilibili/src/bili_utils.dart';
import 'package:bilibili/src/data/model/creator_profile.dart';
import 'package:bilibili/src/data/model/video_model.dart';
import 'package:bpi/bpi.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> loadFake(String key) {
  final candidatePaths = [
    'packages/bilibili/bpi/testing/$key.json',
    'bpi/testing/$key.json',
    'testing/$key.json',
  ];
  for (final path in candidatePaths) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  throw StateError('Fake file $key not found');
}

void main() {
  group('normalizeBiliUrl tests', () {
    test('handles null and empty strings safely', () {
      expect(normalizeBiliUrl(null), isNull);
      expect(normalizeBiliUrl(''), isNull);
    });

    test('prefixes scheme-relative URLs with https:', () {
      expect(
        normalizeBiliUrl('//i0.hdslb.com/bfs/archive/pic.jpg'),
        equals('https://i0.hdslb.com/bfs/archive/pic.jpg'),
      );
    });

    test('converts http:// URLs to https://', () {
      expect(
        normalizeBiliUrl('http://i0.hdslb.com/bfs/archive/pic.jpg'),
        equals('https://i0.hdslb.com/bfs/archive/pic.jpg'),
      );
    });

    test('preserves already secure https:// URLs without duplication', () {
      expect(
        normalizeBiliUrl('https://i0.hdslb.com/bfs/archive/pic.jpg'),
        equals('https://i0.hdslb.com/bfs/archive/pic.jpg'),
      );
    });
  });

  group('Model DTO URL normalization tests', () {
    test(
      'NetworkVideoSearchResultX.asModel normalizes thumbnailUrl from fixture',
      () {
        final json = loadFake('search_video');
        final data = json['data'] as Map<String, dynamic>;
        final result = NetworkSearchResult.fromJson(data);
        final video = result.result.video.first;

        final model = video.asModel();
        expect(model.thumbnailUrl, isNotNull);
        expect(model.thumbnailUrl, startsWith('https://'));
        expect(model.thumbnailUrl, isNot(startsWith('https:https://')));
      },
    );

    test('NetworkLiveUserSearchResultX.asModel normalizes thumbnailUrl from fixture', () {
      final json = loadFake('search_live');
      final data = json['data'] as Map<String, dynamic>;
      final result = NetworkSearchResult.fromJson(data);
      final liveUser = result.result.liveUser.first;

      final model = liveUser.asModel();
      expect(model.thumbnailUrl, isNotNull);
      expect(model.thumbnailUrl, startsWith('https://'));
      expect(model.thumbnailUrl, isNot(startsWith('https:https://')));
    });
  });
}

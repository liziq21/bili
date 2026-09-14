import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  File findFile(String key) {
    final candidatePaths = [
      'packages/bilibili/bpi/testing/$key.json',
      'bpi/testing/$key.json',
      'testing/$key.json',
    ];
    for (final path in candidatePaths) {
      final file = File(path);
      if (file.existsSync()) return file;
    }
    return File(candidatePaths.first);
  }

  Map<String, dynamic> loadFake(String key) {
    final file = findFile(key);
    expect(
      file.existsSync(),
      isTrue,
      reason: 'Fake file $key should exist at ${file.path}',
    );
    final content = file.readAsStringSync();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  group('NetworkSearchResult model tests', () {
    test('deserializes search_all.json correctly', () {
      final json = loadFake('search_all');
      final data = json['data'] as Map<String, dynamic>;
      final result = NetworkSearchResult.fromJson(data);

      expect(result.page, equals(1));
      expect(result.numResults, greaterThan(0));
      expect(result.result, isNotNull);
    });

    test('deserializes search_video.json correctly', () {
      final json = loadFake('search_video');
      final data = json['data'] as Map<String, dynamic>;
      final result = NetworkSearchResult.fromJson(data);

      expect(result.result.video, isNotEmpty);
      final video = result.result.video.first;
      expect(video.bvid, isNotEmpty);
      expect(video.title.text, isNotEmpty);
    });

    test('deserializes search_live.json correctly', () {
      final json = loadFake('search_live');
      final data = json['data'] as Map<String, dynamic>;
      final result = NetworkSearchResult.fromJson(data);

      expect(result.result.liveUser, isNotEmpty);
      final liveUser = result.result.liveUser.first;
      expect(liveUser.uname.text, isNotEmpty);
    });
  });
}

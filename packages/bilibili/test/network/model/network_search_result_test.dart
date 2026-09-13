import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  File findFile(String relativePath) {
    var file = File(relativePath);
    if (!file.existsSync()) {
      file = File('packages/bilibili/$relativePath');
    }
    return file;
  }

  Map<String, dynamic> loadFake(String path) {
    final file = findFile(path);
    expect(
      file.existsSync(),
      isTrue,
      reason: 'Fake file $path should exist at ${file.path}',
    );
    final content = file.readAsStringSync();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  group('NetworkSearchResult model tests', () {
    test('deserializes search.json correctly', () {
      final json = loadFake('testing/network/fakes/search/search.json');
      final data = json['data'] as Map<String, dynamic>;
      final result = NetworkSearchResult.fromJson(data);

      expect(result.page, equals(1));
      expect(result.numResults, greaterThan(0));
      expect(result.result, isNotNull);
    });

    test('deserializes type_search.json correctly', () {
      final json = loadFake('testing/network/fakes/search/type_search.json');
      final data = json['data'] as Map<String, dynamic>;
      final result = NetworkSearchResult.fromJson(data);

      expect(result.result.video, isNotEmpty);
      final video = result.result.video.first;
      expect(video.bvid, isNotEmpty);
      expect(video.title.text, isNotEmpty);
    });

    test('deserializes live_search.json correctly', () {
      final json = loadFake('testing/network/fakes/search/live_search.json');
      final data = json['data'] as Map<String, dynamic>;
      final result = NetworkSearchResult.fromJson(data);

      expect(result.result.liveUser, isNotEmpty);
      final liveUser = result.result.liveUser.first;
      expect(liveUser.uname.text, isNotEmpty);
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixtureMap(String name) {
    final file = File('testing/$name');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'Fixture file testing/$name should exist',
    );
    final content = file.readAsStringSync();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  dynamic loadFixtureDynamic(String name) {
    final file = File('testing/$name');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'Fixture file testing/$name should exist',
    );
    final content = file.readAsStringSync();
    return jsonDecode(content);
  }

  group('YouTube Fixtures Tests', () {
    test('parses real search_video.json correctly', () {
      final json = loadFixtureMap('search_video.json');

      expect(json, isNotNull);
      expect(json.containsKey('contents'), isTrue);

      final contents =
          json['contents']?['twoColumnSearchResultsRenderer']?['primaryContents']?['sectionListRenderer']?['contents']
              as List?;
      expect(contents, isNotNull);
      expect(contents, isNotEmpty);
    });

    test('parses real search_channel.json correctly', () {
      final json = loadFixtureMap('search_channel.json');

      expect(json, isNotNull);
      expect(json.containsKey('contents'), isTrue);

      final contents =
          json['contents']?['twoColumnSearchResultsRenderer']?['primaryContents']?['sectionListRenderer']?['contents']
              as List?;
      expect(contents, isNotNull);
      expect(contents, isNotEmpty);
    });

    test('parses real search_suggest.json correctly', () {
      final json = loadFixtureDynamic('search_suggest.json');

      expect(json, isA<List>());
      final list = json as List;
      expect(list.length, greaterThanOrEqualTo(2));
      expect(list[1], isA<List>());
      final suggestions = list[1] as List;
      expect(suggestions, isNotEmpty);
    });
  });
}

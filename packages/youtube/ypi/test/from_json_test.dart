import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:ypi/ypi.dart';

void main() {
  Map<String, dynamic> loadFixtureMap(String name) {
    final file = File('testing/$name');
    expect(file.existsSync(), isTrue, reason: 'Fixture $name should exist');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('parses the real video search fixture into typed renderers', () {
    final response = NetworkYouTubeVideoSearchResponse.fromJson(
      loadFixtureMap('search_video.json'),
    );
    final sections = response
        .contents!
        .twoColumnSearchResultsRenderer!
        .primaryContents!
        .sectionListRenderer!
        .contents;
    expect(sections, isNotEmpty);
    expect(sections.whereType<NetworkYouTubeItemSectionRenderer>(), isNotEmpty);
    expect(sections.whereType<NetworkYouTubeContinuationSection>(), isNotEmpty);
  });

  test('parses the real channel search fixture into typed renderers', () {
    final response = NetworkYouTubeChannelSearchResponse.fromJson(
      loadFixtureMap('search_channel.json'),
    );
    final sections = response
        .contents!
        .twoColumnSearchResultsRenderer!
        .primaryContents!
        .sectionListRenderer!
        .contents;
    expect(sections, isNotEmpty);
    expect(sections.whereType<NetworkYouTubeItemSectionRenderer>(), isNotEmpty);
  });

  test('parses the real suggest fixture into a typed suggestion DTO', () {
    final file = File('testing/search_suggest.json');
    expect(file.existsSync(), isTrue);
    final response = NetworkYouTubeSearchSuggestions.fromResponse(
      query: 'flutter',
      responseBody: file.readAsStringSync(),
    );
    expect(response.query, 'flutter');
    expect(response.suggestions, isNotEmpty);
  });
}

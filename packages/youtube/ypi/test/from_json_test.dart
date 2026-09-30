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

  test('parses the real playlist search fixture into typed lockups', () {
    final response = NetworkYouTubePlaylistSearchResponse.fromJson(
      loadFixtureMap('search_playlist.json'),
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
    final playlists = sections
        .whereType<NetworkYouTubeItemSectionRenderer>()
        .expand((section) => section.contents)
        .whereType<NetworkYouTubePlaylistSearchItem>()
        .toList();
    expect(playlists, isNotEmpty);

    final first = playlists.first.renderer;
    expect(first.playlistId, 'PL4cUxeGkcC9jLYyp2Aoh6hcWuxFDX6PBJ');
    expect(first.title, 'Flutter Tutorial for Beginners');
    expect(first.videoCountText, isNotNull);
    expect(first.owner?.text.value, 'Net Ninja');
    expect(first.owner?.browseId, 'UCW5YeuERMmlnqo4oq8vwUpg');
    expect(first.thumbnail?.thumbnails, isNotEmpty);
    expect(first.thumbnail?.thumbnails.first.url, isNotNull);

    for (final item in playlists) {
      expect(item.renderer.playlistId, startsWith('PL'));
    }
  });

  test('non-playlist lockups are dropped rather than mis-typed', () {
    const lockup = {
      'lockupViewModel': {
        'contentId': 'dQw4w9WgXcQ',
        'metadata': {
          'lockupMetadataViewModel': {
            'title': {'content': 'Not a playlist'},
          },
        },
      },
    };
    final section = NetworkYouTubeItemSectionRenderer.fromJson({
      'itemSectionRenderer': {
        'contents': [lockup],
      },
    });
    expect(section.contents, isEmpty);
  });

  test('parses the real browse fixture into typed header and tabs DTO', () {
    final response = NetworkYouTubeBrowseResponse.fromJson(
      loadFixtureMap('browse.json'),
    );
    expect(response.header, isNotNull);
    expect(response.header?.channelId, 'UCwXdFgeE9KYzlDUR7te5Suq');
    expect(response.header?.avatar, isNotNull);
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

  test('strips non-printable control characters from search suggestions', () {
    const rawResponseBody = '''
window.google.ac.h(["test", [
  ["flutter\\u0000tutorial\\r\\n", 0],
  ["\\u001fbad\\u007f string", 0],
  ["\\u0000\\u001f", 0],
  ["clean query", 0]
]])
''';
    final response = NetworkYouTubeSearchSuggestions.fromResponse(
      query: 'test',
      responseBody: rawResponseBody,
    );
    expect(response.suggestions, [
      'fluttertutorial',
      'bad string',
      'clean query',
    ]);
  });
}

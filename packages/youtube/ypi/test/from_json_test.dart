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

  test('parses the real channel browse fixture into lockup items', () {
    final response = NetworkYouTubeBrowseResponse.fromJson(
      loadFixtureMap('browse.json'),
    );

    // The channel ID is not in the header renderer YouTube now returns; it
    // lives in `metadata.channelMetadataRenderer.externalId`.
    expect(response.header?.channelId, 'UCuAXFkgsw1L7xaCfnd5JJOw');
    expect(response.header?.title, 'Rick Astley');

    expect(response.tabs, hasLength(8));
    expect(response.tabs.where((tab) => tab.selected).map((tab) => tab.title), [
      '视频',
    ]);

    // A 2026 channel grid carries 30 lockups; the previous implementation
    // expected `videoRenderer` and produced an empty list here.
    expect(response.items, hasLength(30));
    final first = response.items.first;
    expect(first.contentId, 'PXC_PYeB6F8');
    expect(first.contentType, 'LOCKUP_CONTENT_TYPE_VIDEO');
    expect(
      first.title,
      'Rick Astley - Angels On My Side (Live at The O2, London, April 2026)',
    );
    expect(first.metadataRows, ['10万次观看', '3个月前']);
    expect(first.thumbnail?.thumbnails, isNotEmpty);
    expect(first.thumbnail?.thumbnails.first.url, contains('PXC_PYeB6F8'));

    for (final item in response.items) {
      expect(item.contentId, isNotEmpty);
      expect(item.title, isNotNull);
    }

    expect(response.continuationToken, isNotNull);
  });

  test('keeps the entries a continuation page returns', () {
    // A continuation response holds the same `richItemRenderer` entries the
    // grid came from, wrapped in `appendContinuationItemsAction`. Reading only
    // sections there kept the token and dropped every entry.
    final response = NetworkYouTubeBrowseResponse.fromJson(
      loadFixtureMap('browse_continuation.json'),
    );

    expect(response.items, hasLength(30));
    expect(response.items.first.contentId, isNotEmpty);
    expect(response.items.first.title, isNotNull);
    expect(response.items.any((item) => item.metadataRows.isNotEmpty), isTrue);
  });

  test('an ERROR alert is raised instead of parsing as an empty channel', () {
    // YouTube answers HTTP 200 with `alerts[].alertRenderer.type == ERROR`
    // when a channel is gone. This is the response the previous
    // `browse.json` fixture held.
    expect(
      () => NetworkYouTubeBrowseResponse.fromJson(<String, dynamic>{
        'alerts': <Map<String, dynamic>>[
          <String, dynamic>{
            'alertRenderer': <String, dynamic>{
              'type': 'ERROR',
              'text': <String, dynamic>{'simpleText': '此频道不存在。'},
            },
          },
        ],
      }),
      throwsA(isA<YpiInnerTubeException>()),
    );
  });

  test('a header lacking a channel ID does not yield an empty channel ID', () {
    // `pageHeaderRenderer` carries no channel ID, so one must come from
    // `metadata.channelMetadataRenderer.externalId`. The previous code
    // substituted an empty string, which then failed the next request against
    // the same channel.
    final withoutId = NetworkYouTubeBrowseResponse.fromJson(<String, dynamic>{
      'header': <String, dynamic>{
        'pageHeaderRenderer': <String, dynamic>{'pageTitle': 'No ID'},
      },
    });
    expect(withoutId.header, isNull);

    expect(
      () => NetworkYouTubeChannelHeader.fromJson(<String, dynamic>{
        'pageHeaderRenderer': <String, dynamic>{'pageTitle': 'No ID'},
      }),
      throwsA(isA<FormatException>()),
    );
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

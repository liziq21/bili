import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:ypi/ypi.dart';

Map<String, dynamic> _loadFixture(String name) {
  final file = File('testing/$name');
  expect(file.existsSync(), isTrue, reason: 'Fixture $name should exist');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  group('NetworkYouTubeResolveUrlResponse', () {
    test('parses the captured watch URL response', () {
      final response = NetworkYouTubeResolveUrlResponse.fromJson(
        _loadFixture('resolve_url.json'),
      );

      expect(response.videoId, 'dQw4w9WgXcQ');
      expect(response.playlistId, isNull);
      expect(response.browseId, isNull);
      expect(response.canonicalUrl, contains('/watch?v=dQw4w9WgXcQ'));
      expect(response.webPageType, 'WEB_PAGE_TYPE_WATCH');
    });

    test('parses a browse endpoint response', () {
      final response = NetworkYouTubeResolveUrlResponse.fromJson({
        'endpoint': {
          'commandMetadata': {
            'webCommandMetadata': {
              'url': '/@FlutterDev',
              'webPageType': 'WEB_PAGE_TYPE_CHANNEL',
            },
          },
          'browseEndpoint': {'browseId': 'UC123'},
        },
      });

      expect(response.browseId, 'UC123');
      expect(response.videoId, isNull);
    });

    test('parses a Shorts reel endpoint response', () {
      final response = NetworkYouTubeResolveUrlResponse.fromJson({
        'endpoint': {
          'commandMetadata': {
            'webCommandMetadata': {
              'url': '/shorts/abc123',
              'webPageType': 'WEB_PAGE_TYPE_SHORTS',
            },
          },
          'reelWatchEndpoint': {'videoId': 'abc123'},
        },
      });

      expect(response.videoId, 'abc123');
      expect(response.browseId, isNull);
      expect(response.webPageType, 'WEB_PAGE_TYPE_SHORTS');
    });

    test('rejects an endpoint without any id', () {
      expect(
        () => NetworkYouTubeResolveUrlResponse.fromJson({
          'endpoint': {'commandMetadata': <String, dynamic>{}},
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('surfaces an InnerTube error envelope', () {
      expect(
        () => NetworkYouTubeResolveUrlResponse.fromJson({
          'error': {'code': 400, 'message': 'Invalid URL'},
        }),
        throwsA(
          isA<YpiInnerTubeException>().having(
            (error) => error.reason,
            'reason',
            'Invalid URL',
          ),
        ),
      );
    });
  });

  group('YoutubeService.resolveUrl', () {
    test('posts the URL and parses the response', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(_loadFixture('resolve_url.json')),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = YoutubeService(httpClient: client);
      addTearDown(service.close);

      final response = await service.resolveUrl(
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );

      expect(requests, hasLength(1));
      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, '/youtubei/v1/navigation/resolve_url');
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(body['url'], 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      expect(
        (body['context'] as Map<String, dynamic>)['client'],
        isA<Map<String, dynamic>>(),
      );
      expect(response.videoId, 'dQw4w9WgXcQ');
    });

    test('rejects an empty URL without sending a request', () async {
      var called = false;
      final client = MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      });
      final service = YoutubeService(httpClient: client);
      addTearDown(service.close);

      expect(service.resolveUrl('   '), throwsA(isA<YpiJsonException>()));
      expect(called, isFalse);
    });

    test('maps a non-2xx response to YpiHttpException', () async {
      final service = YoutubeService(
        httpClient: MockClient((_) async => http.Response('{}', 500)),
      );
      addTearDown(service.close);

      expect(
        service.resolveUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        throwsA(
          isA<YpiHttpException>().having(
            (error) => error.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });
  });

  group('NetworkYouTubeLiveDirectoryResponse', () {
    test('parses the captured live directory fixture', () {
      final response = NetworkYouTubeLiveDirectoryResponse.fromJson(
        _loadFixture('live_directory.json'),
      );

      expect(response.videos, hasLength(64));
      expect(
        response.continuationToken,
        isNull,
        reason:
            'the captured page has no continuation item; token extraction '
            'is covered by the synthetic test below',
      );
      expect(response.videos.first.videoId, isNotEmpty);
      expect(response.videos.first.title?.value, isNotNull);
      expect(
        response.videos.map((video) => video.videoId).toSet(),
        hasLength(response.videos.length),
        reason: 'collector must not return the same video twice',
      );
    });

    test('rejects a browse response without videoRenderer entries', () {
      expect(
        () => NetworkYouTubeLiveDirectoryResponse.fromJson({
          'contents': {
            'twoColumnBrowseResultsRenderer': {
              'tabs': [
                {
                  'tabRenderer': {
                    'content': {
                      'richGridRenderer': {
                        'contents': [
                          {
                            'richSectionRenderer': {
                              'content': {'feedNudgeRenderer': {}},
                            },
                          },
                        ],
                      },
                    },
                  },
                },
              ],
            },
          },
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('extracts a continuation token from a continuation item', () {
      final response = NetworkYouTubeLiveDirectoryResponse.fromJson({
        'contents': {
          'videoRenderer': {'videoId': 'abc123'},
          'continuationItemRenderer': {
            'continuationEndpoint': {
              'continuationCommand': {'token': 'NEXT_PAGE'},
            },
          },
        },
      });

      expect(response.videos.single.videoId, 'abc123');
      expect(response.continuationToken, 'NEXT_PAGE');
    });
  });

  group('YoutubeService.browseLiveDirectory', () {
    test('browses the live directory browse id', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(_loadFixture('live_directory.json')),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = YoutubeService(httpClient: client);
      addTearDown(service.close);

      final response = await service.browseLiveDirectory();

      expect(requests.single.url.path, '/youtubei/v1/browse');
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(body['browseId'], 'UC4R8DWoMoI7CAwX8_LjQHig');
      expect(body['continuation'], isNull);
      expect(response.videos, hasLength(64));
    });

    test('sends a continuation token instead of browseId', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(_loadFixture('live_directory.json')),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = YoutubeService(httpClient: client);
      addTearDown(service.close);

      await service.browseLiveDirectory(continuation: 'LIVE_DIRECTORY_TOKEN');

      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(body['continuation'], 'LIVE_DIRECTORY_TOKEN');
      expect(body['browseId'], isNull);
    });

    test('maps a non-2xx response to YpiHttpException', () async {
      final service = YoutubeService(
        httpClient: MockClient((_) async => http.Response('{}', 503)),
      );
      addTearDown(service.close);

      expect(
        service.browseLiveDirectory(),
        throwsA(
          isA<YpiHttpException>().having(
            (error) => error.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
    });
  });

  group('NetworkYouTubeMusicSearchSuggestions', () {
    test('parses the captured music suggestion fixture', () {
      final response = NetworkYouTubeMusicSearchSuggestions.fromJson(
        _loadFixture('music_suggest.json'),
        query: 'flut',
      );

      expect(response.query, 'flut');
      expect(response.suggestions, hasLength(16));
      expect(response.suggestions.first.text, isNotEmpty);
      expect(response.suggestions.first.searchQuery, isNotEmpty);
    });

    test('returns an empty list when no suggestion section is present', () {
      final response = NetworkYouTubeMusicSearchSuggestions.fromJson(const {
        'contents': <Object>[],
      }, query: 'x');

      expect(response.suggestions, isEmpty);
    });
  });

  group('YoutubeService.getMusicSearchSuggestions', () {
    test('posts the input with the WEB_REMIX client context', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(_loadFixture('music_suggest.json')),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = YoutubeService(httpClient: client);
      addTearDown(service.close);

      final response = await service.getMusicSearchSuggestions('flut');

      final request = requests.single;
      expect(request.url.host, 'music.youtube.com');
      expect(request.url.path, '/youtubei/v1/music/get_search_suggestions');
      expect(request.headers['X-YouTube-Client-Name'], '67');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['input'], 'flut');
      final clientContext =
          (body['context'] as Map<String, dynamic>)['client']
              as Map<String, dynamic>;
      expect(clientContext['clientName'], 'WEB_REMIX');
      expect(response.suggestions, hasLength(16));
    });

    test('maps a non-2xx response to YpiHttpException', () async {
      final service = YoutubeService(
        httpClient: MockClient((_) async => http.Response('{}', 500)),
      );
      addTearDown(service.close);

      expect(
        service.getMusicSearchSuggestions('flut'),
        throwsA(isA<YpiHttpException>()),
      );
    });
  });

  group('NetworkYouTubeMusicSearchResponse', () {
    test('parses the captured music search fixture', () {
      final response = NetworkYouTubeMusicSearchResponse.fromJson(
        _loadFixture('music_search.json'),
      );

      expect(response.items, hasLength(18));
      expect(
        response.continuationToken,
        isNull,
        reason:
            'the captured page has no continuation item; token extraction '
            'is covered by the synthetic test below',
      );
      final video = response.items.firstWhere((item) => item.videoId != null);
      expect(video.title, isNotEmpty);
      expect(video.subtitle, isNotEmpty);
      expect(video.thumbnailUrl, isNotEmpty);
    });

    test('keeps artist entries that carry only a browse id', () {
      final response = NetworkYouTubeMusicSearchResponse.fromJson({
        'contents': [
          {
            'musicResponsiveListItemRenderer': {
              'flexColumns': [
                {
                  'musicResponsiveListItemFlexColumnRenderer': {
                    'text': {
                      'runs': [
                        {'text': 'Artist'},
                      ],
                    },
                  },
                },
              ],
              'navigationEndpoint': {
                'browseEndpoint': {
                  'browseId': 'UCARTIST',
                  'browseEndpointContextSupportedConfigs': {
                    'browseEndpointContextMusicConfig': {
                      'pageType': 'MUSIC_PAGE_TYPE_ARTIST',
                    },
                  },
                },
              },
            },
          },
        ],
      });

      final item = response.items.single;
      expect(item.title, 'Artist');
      expect(item.browseId, 'UCARTIST');
      expect(item.pageType, 'MUSIC_PAGE_TYPE_ARTIST');
      expect(item.videoId, isNull);
    });

    test('extracts a continuation token from a continuation item', () {
      final response = NetworkYouTubeMusicSearchResponse.fromJson({
        'contents': [
          {
            'musicResponsiveListItemRenderer': {
              'flexColumns': [
                {
                  'musicResponsiveListItemFlexColumnRenderer': {
                    'text': {
                      'runs': [
                        {'text': 'Song'},
                      ],
                    },
                  },
                },
              ],
            },
          },
          {
            'continuationItemRenderer': {
              'continuationEndpoint': {
                'continuationCommand': {'token': 'NEXT_PAGE'},
              },
            },
          },
        ],
      });

      expect(response.items.single.title, 'Song');
      expect(response.continuationToken, 'NEXT_PAGE');
    });
  });

  group('YoutubeService.searchMusic', () {
    test('posts the query with the WEB_REMIX client context', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(_loadFixture('music_search.json')),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = YoutubeService(httpClient: client);
      addTearDown(service.close);

      final response = await service.searchMusic('Taylor Swift');

      final request = requests.single;
      expect(request.url.host, 'music.youtube.com');
      expect(request.url.path, '/youtubei/v1/search');
      expect(request.headers['X-YouTube-Client-Name'], '67');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['query'], 'Taylor Swift');
      expect(body['params'], isNull);
      expect(response.items, hasLength(18));
    });

    test('sends params and a continuation token when provided', () async {
      final bodies = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response(
          jsonEncode(_loadFixture('music_search.json')),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = YoutubeService(httpClient: client);
      addTearDown(service.close);

      await service.searchMusic('Taylor Swift', params: 'MUSIC_PARAMS');
      await service.searchMusic('Taylor Swift', continuation: 'MUSIC_TOKEN');

      expect(bodies[0]['params'], 'MUSIC_PARAMS');
      expect(bodies[1]['continuation'], 'MUSIC_TOKEN');
      expect(bodies[1]['query'], isNull);
    });

    test('maps a non-2xx response to YpiHttpException', () async {
      final service = YoutubeService(
        httpClient: MockClient((_) async => http.Response('{}', 500)),
      );
      addTearDown(service.close);

      expect(
        service.searchMusic('Taylor Swift'),
        throwsA(isA<YpiHttpException>()),
      );
    });
  });
}

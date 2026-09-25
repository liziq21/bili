import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:ypi/ypi.dart';

void main() {
  group('YoutubeService', () {
    test(
      'searchVideos sends the request shape and returns a typed DTO',
      () async {
        final mockJsonResponse = {
          'contents': {
            'twoColumnSearchResultsRenderer': {
              'primaryContents': {
                'sectionListRenderer': {
                  'contents': [
                    {
                      'itemSectionRenderer': {
                        'contents': [
                          {
                            'videoRenderer': {
                              'videoId': 'test_id_123',
                              'title': {
                                'runs': [
                                  {'text': 'Test Flutter Video'},
                                ],
                              },
                              'thumbnail': {
                                'thumbnails': [
                                  {'url': 'https://img.youtube.com/thumb.jpg'},
                                ],
                              },
                              'viewCountText': {'simpleText': '1,234 views'},
                              'publishedTimeText': {'simpleText': '2 days ago'},
                              'lengthText': {'simpleText': '10:30'},
                              'ownerText': {
                                'runs': [
                                  {
                                    'text': 'Flutter Creator',
                                    'navigationEndpoint': {
                                      'browseEndpoint': {'browseId': 'UC12345'},
                                    },
                                  },
                                ],
                              },
                            },
                          },
                          {
                            'videoRenderer': {
                              'title': {'simpleText': 'Missing id'},
                            },
                          },
                        ],
                      },
                    },
                  ],
                },
              },
            },
          },
        };

        final mockClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/youtubei/v1/search');
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['query'], 'flutter');
          expect(body['context'], isA<Map<String, dynamic>>());
          return http.Response(
            json.encode(mockJsonResponse),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = YoutubeService(httpClient: mockClient);
        final response = await service.searchVideos('flutter');

        final section =
            response
                    .contents!
                    .twoColumnSearchResultsRenderer!
                    .primaryContents!
                    .sectionListRenderer!
                    .contents
                    .single
                as NetworkYouTubeItemSectionRenderer;
        expect(section.contents, hasLength(1));
        final video =
            (section.contents.single as NetworkYouTubeVideoSearchItem).renderer;
        expect(video.videoId, 'test_id_123');
        expect(video.title?.value, 'Test Flutter Video');
        expect(video.viewCountText?.value, '1,234 views');
        expect(video.owner?.browseId, 'UC12345');
        service.close();
      },
    );

    test('searchChannels returns a typed channel envelope', () async {
      final mockJsonResponse = {
        'contents': {
          'twoColumnSearchResultsRenderer': {
            'primaryContents': {
              'sectionListRenderer': {
                'contents': [
                  {
                    'itemSectionRenderer': {
                      'contents': [
                        {
                          'channelRenderer': {
                            'channelId': 'UC_CHANNEL_1',
                            'title': {'simpleText': 'Channel Title'},
                            'thumbnail': {
                              'thumbnails': [
                                {'url': 'https://img.youtube.com/avatar.jpg'},
                              ],
                            },
                            'videoCountText': {'simpleText': '100 videos'},
                          },
                        },
                      ],
                    },
                  },
                ],
              },
            },
          },
        },
      };

      final service = YoutubeService(
        httpClient: MockClient(
          (_) async => http.Response(json.encode(mockJsonResponse), 200),
        ),
      );
      final response = await service.searchChannels('flutter');
      final section =
          response
                  .contents!
                  .twoColumnSearchResultsRenderer!
                  .primaryContents!
                  .sectionListRenderer!
                  .contents
                  .single
              as NetworkYouTubeItemSectionRenderer;
      final channel =
          (section.contents.single as NetworkYouTubeChannelSearchItem).renderer;
      expect(channel.channelId, 'UC_CHANNEL_1');
      expect(channel.title?.value, 'Channel Title');
      expect(channel.videoCountText?.value, '100 videos');
      service.close();
    });

    test('getSearchSuggestions returns query and typed suggestions', () async {
      final client = MockClient(
        (_) async => http.Response(
          'window.google.ac.h(["flutter", [["flutter tutorial"], ["flutter course"]]])',
          200,
        ),
      );
      final service = YoutubeService(httpClient: client);
      final response = await service.getSearchSuggestions('flutter');

      expect(response.query, 'flutter');
      expect(response.suggestions, ['flutter tutorial', 'flutter course']);
      service.close();
    });

    test('throws typed HTTP and InnerTube exceptions', () async {
      final httpService = YoutubeService(
        httpClient: MockClient((_) async => http.Response('unavailable', 503)),
      );
      await expectLater(
        httpService.searchVideos('flutter'),
        throwsA(isA<YpiHttpException>()),
      );
      httpService.close();

      final innerTubeService = YoutubeService(
        httpClient: MockClient(
          (_) async => http.Response(
            json.encode({
              'error': {
                'code': 400,
                'message': 'Invalid request',
                'continuation': 'diagnostic-token',
              },
            }),
            200,
          ),
        ),
      );
      await expectLater(
        innerTubeService.searchVideos('flutter'),
        throwsA(
          isA<YpiInnerTubeException>()
              .having((error) => error.code, 'code', 400)
              .having(
                (error) => error.continuation,
                'continuation',
                'diagnostic-token',
              ),
        ),
      );
      innerTubeService.close();
    });

    test('throws typed JSON and network exceptions', () async {
      final jsonService = YoutubeService(
        httpClient: MockClient(
          (_) async => http.Response('window.google.ac.h(not-json)', 200),
        ),
      );
      await expectLater(
        jsonService.getSearchSuggestions('flutter'),
        throwsA(isA<YpiJsonException>()),
      );
      jsonService.close();

      final networkService = YoutubeService(
        httpClient: MockClient(
          (_) async => throw http.ClientException('offline'),
        ),
      );
      await expectLater(
        networkService.searchVideos('flutter'),
        throwsA(isA<YpiNetworkException>()),
      );
      networkService.close();
    });
  });
}

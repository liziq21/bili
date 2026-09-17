import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:ypi/ypi.dart';

void main() {
  group('YoutubeService Tests', () {
    test('searchVideos parses InnerTube JSON response correctly', () async {
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
                            'descriptionSnippet': {
                              'runs': [
                                {'text': 'A video description'},
                              ],
                            },
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
        if (request.url.path.contains('/youtubei/v1/search')) {
          expect(request.method, equals('POST'));
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['context'], isNotNull); // Injected by interceptor
          expect(body['query'], equals('flutter'));

          return http.Response(
            json.encode(mockJsonResponse),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not found', 404);
      });

      final service = YoutubeService(httpClient: mockClient);
      final (videos, continuation) = await service.searchVideos('flutter');

      expect(videos.length, equals(1));
      final video = videos.first;
      expect(video.id, equals('test_id_123'));
      expect(video.title, equals('Test Flutter Video'));
      expect(video.viewCount, equals(1234));
      expect(video.duration, equals(630)); // 10 min 30 sec
      expect(video.creatorProfileName, equals('Flutter Creator'));
      expect(video.creatorProfileId, equals('UC12345'));
      expect(continuation, isNull);

      service.close();
    });

    test('searchChannels parses channel search response', () async {
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

      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode(mockJsonResponse),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = YoutubeService(httpClient: mockClient);
      final (channels, continuation) = await service.searchChannels('flutter');

      expect(channels.length, equals(1));
      final channel = channels.first;
      expect(channel.id, equals('UC_CHANNEL_1'));
      expect(channel.name, equals('Channel Title'));
      expect(channel.videos, equals(100));

      service.close();
    });

    test('getSearchSuggestions parses Google suggest response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          'window.google.ac.h(["flutter", [["flutter tutorial"], ["flutter course"]]])',
          200,
        );
      });

      final service = YoutubeService(httpClient: mockClient);
      final suggestions = await service.getSearchSuggestions('flutter');

      expect(suggestions, equals(['flutter tutorial', 'flutter course']));
      service.close();
    });
  });
}

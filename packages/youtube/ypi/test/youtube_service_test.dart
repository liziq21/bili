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

    test('searchPlaylists sends the request shape and returns typed playlist envelope', () async {
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
                          'lockupViewModel': {
                            'contentId': 'PL_PLAYLIST_1',
                            'contentImage': {
                              'collectionThumbnailViewModel': {
                                'primaryThumbnail': {
                                  'thumbnailViewModel': {
                                    'image': {
                                      'sources': [
                                        {
                                          'url': 'https://img.youtube.com/playlist.jpg',
                                          'width': 360,
                                          'height': 202,
                                        },
                                      ],
                                    },
                                    'overlays': [
                                      {
                                        'thumbnailOverlayBadgeViewModel': {
                                          'thumbnailBadges': [
                                            {
                                              'thumbnailBadgeViewModel': {
                                                'text': '25 lessons',
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
                            'metadata': {
                              'lockupMetadataViewModel': {
                                'title': {'content': 'Playlist Title'},
                                'metadata': {
                                  'contentMetadataViewModel': {
                                    'metadataRows': [
                                      {
                                        'metadataParts': [
                                          {
                                            'text': {
                                              'content': 'Playlist Owner',
                                              'commandRuns': [
                                                {
                                                  'onTap': {
                                                    'innertubeCommand': {
                                                      'browseEndpoint': {
                                                        'browseId':
                                                            'UC_OWNER_1',
                                                      },
                                                    },
                                                  },
                                                },
                                              ],
                                            },
                                          },
                                        ],
                                        'lockupContentMetadataRowExtension': {
                                          'contentType': 'METADATA_ROW_CONTENT_TYPE_BYLINE',
                                        },
                                      },
                                    ],
                                  },
                                },
                              },
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
        expect(request.method, 'POST');
        expect(request.url.path, '/youtubei/v1/search');
        final body = json.decode(request.body) as Map<String, dynamic>;
        expect(body['query'], 'flutter playlist');
        expect(body['context'], isA<Map<String, dynamic>>());
        expect(body['params'], 'QgIQAw==');
        return http.Response(
          json.encode(mockJsonResponse),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = YoutubeService(httpClient: mockClient);
      final response = await service.searchPlaylists('flutter playlist');
      final section =
          response
                  .contents!
                  .twoColumnSearchResultsRenderer!
                  .primaryContents!
                  .sectionListRenderer!
                  .contents
                  .single
              as NetworkYouTubeItemSectionRenderer;
      final playlist =
          (section.contents.single as NetworkYouTubePlaylistSearchItem)
              .renderer;
      expect(playlist.playlistId, 'PL_PLAYLIST_1');
      expect(playlist.title, 'Playlist Title');
      expect(playlist.videoCountText, '25 lessons');
      expect(playlist.owner?.text.value, 'Playlist Owner');
      expect(playlist.owner?.browseId, 'UC_OWNER_1');
      expect(
        playlist.thumbnail?.thumbnails.single.url,
        contains('playlist.jpg'),
      );
      service.close();
    });

    test(
      'browse sends request shape and returns typed browse envelope',
      () async {
        final mockJsonResponse = {
          'header': {
            'c4TabbedHeaderRenderer': {
              'channelId': 'UC_BROWSE_1',
              'title': 'Test Channel',
              'avatar': {
                'thumbnails': [
                  {'url': 'https://img.youtube.com/avatar.jpg'},
                ],
              },
            },
          },
          'contents': {
            'twoColumnBrowseResultsRenderer': {
              'tabs': [
                {
                  'tabRenderer': {
                    'title': 'Home',
                    'selected': true,
                    'content': {
                      'richGridRenderer': {
                        'contents': [
                          {
                            'richItemRenderer': {
                              'content': {
                                'videoRenderer': {
                                  'videoId': 'browse_vid_1',
                                  'title': {'simpleText': 'Browse Video 1'},
                                },
                              },
                            },
                          },
                          {
                            'continuationItemRenderer': {
                              'continuationEndpoint': {
                                'continuationCommand': {
                                  'token': 'cont_token_123',
                                },
                              },
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
        };

        final mockClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/youtubei/v1/browse');
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['browseId'], 'UC_BROWSE_1');
          return http.Response(
            json.encode(mockJsonResponse),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = YoutubeService(httpClient: mockClient);
        final response = await service.browse(browseId: 'UC_BROWSE_1');

        expect(response.header, isNotNull);
        expect(response.header?.channelId, 'UC_BROWSE_1');
        expect(response.header?.title, 'Test Channel');
        expect(response.tabs, hasLength(1));
        expect(response.tabs.first.title, 'Home');
        expect(response.items, hasLength(1));
        final item = response.items.single as NetworkYouTubeVideoSearchItem;
        expect(item.renderer.videoId, 'browse_vid_1');
        expect(response.continuationToken, 'cont_token_123');

        service.close();
      },
    );

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

    test('sanitizes control characters in search queries', () async {
      final client = MockClient((request) async {
        if (request.url.path.contains('search')) {
          if (request.method == 'GET') {
            expect(request.url.queryParameters['q'], 'flutter search');
            return http.Response(
              'window.google.ac.h(["flutter search", [["flutter search tutorial"]]])',
              200,
            );
          }
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['query'], 'flutter search');
          return http.Response(json.encode({'contents': {}}), 200);
        }
        if (request.url.path.contains('browse')) {
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['browseId'], 'UC_TEST');
          return http.Response(json.encode({'contents': {}}), 200);
        }
        return http.Response('', 404);
      });

      final service = YoutubeService(httpClient: client);

      final suggestResponse = await service.getSearchSuggestions(
        'flutter\r\n\x00 search\x1f',
      );
      expect(suggestResponse.query, 'flutter search');

      await service.searchVideos('flutter\r\n\x00 search\x1f');
      await service.searchChannels('flutter\r\n\x00 search\x1f');
      await service.searchPlaylists('flutter\r\n\x00 search\x1f');
      await service.browse(browseId: 'UC\r\n\x00_TEST\x1f');

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
      await expectLater(
        httpService.searchPlaylists('flutter'),
        throwsA(isA<YpiHttpException>()),
      );
      await expectLater(
        httpService.browse(browseId: 'UC123'),
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
        innerTubeService.browse(browseId: 'UC123'),
        throwsA(
          isA<YpiInnerTubeException>().having(
            (error) => error.code,
            'code',
            400,
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
      await expectLater(
        innerTubeService.searchPlaylists('flutter'),
        throwsA(
          isA<YpiInnerTubeException>().having(
            (error) => error.code,
            'code',
            400,
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
      await expectLater(
        networkService.searchPlaylists('flutter'),
        throwsA(isA<YpiNetworkException>()),
      );
      await expectLater(
        networkService.browse(browseId: 'UC123'),
        throwsA(isA<YpiNetworkException>()),
      );
      networkService.close();
    });
  });
}

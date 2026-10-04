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

    test('getWatchNext maps a non-2xx response to YpiHttpException', () async {
      final mockClient = MockClient((request) async {
        return http.Response('unavailable', 503);
      });
      final service = YoutubeService(httpClient: mockClient);
      await expectLater(
        service.getWatchNext(videoId: 'VIDEO_NEXT_123'),
        throwsA(isA<YpiHttpException>()),
      );
    });

    test('getWatchNext maps an ERROR alert to YpiInnerTubeException', () async {
      // YouTube 对失效或受限视频返回 HTTP 200、无顶层 error，但带
      // alerts[].alertRenderer(type: ERROR)。不归类成业务错误的话，调用方只会
      // 看到一个「缺标题」的 FormatException，分不清是业务拒绝还是结构损坏。
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'alerts': [
              {
                'alertRenderer': {
                  'type': 'ERROR',
                  'text': {'simpleText': 'Video unavailable'},
                },
              },
            ],
          }),
          200,
        );
      });
      final service = YoutubeService(httpClient: mockClient);
      await expectLater(
        service.getWatchNext(videoId: 'VIDEO_NEXT_123'),
        throwsA(
          isA<YpiInnerTubeException>().having(
            (e) => e.reason,
            'reason',
            'Video unavailable',
          ),
        ),
      );
    });

    test(
      'getWatchNext posts to next and returns typed video details',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/youtubei/v1/next');
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['videoId'], 'VIDEO_NEXT_123');
          expect(body['context'], isA<Map<String, dynamic>>());
          return http.Response(
            json.encode({
              'currentVideoEndpoint': {
                'watchEndpoint': {'videoId': 'VIDEO_NEXT_123'},
              },
              'contents': {
                'twoColumnWatchNextResults': {
                  'results': {
                    'results': {
                      'contents': [
                        {
                          'videoPrimaryInfoRenderer': {
                            'title': {
                              'runs': [
                                {'text': 'Sample Video Title'},
                              ],
                            },
                            'viewCount': {
                              'videoViewCountRenderer': {
                                'viewCount': {'simpleText': '1,000 views'},
                              },
                            },
                            'relativeDateText': {'simpleText': '1 day ago'},
                          },
                        },
                        {
                          'videoSecondaryInfoRenderer': {
                            'owner': {
                              'videoOwnerRenderer': {
                                'title': {
                                  'runs': [
                                    {'text': 'Sample Creator'},
                                  ],
                                },
                                'navigationEndpoint': {
                                  'browseEndpoint': {
                                    'browseId': 'UC_CREATOR_1',
                                  },
                                },
                              },
                            },
                            'description': {
                              'runs': [
                                {'text': 'Video Description text'},
                              ],
                            },
                          },
                        },
                      ],
                    },
                  },
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = YoutubeService(httpClient: mockClient);
        final response = await service.getWatchNext(videoId: 'VIDEO_NEXT_123');
        expect(response.videoId, 'VIDEO_NEXT_123');
        expect(response.title, 'Sample Video Title');
        expect(response.viewCountText, '1,000 views');
        expect(response.publishedTimeText, '1 day ago');
        expect(response.owner?.channelId, 'UC_CREATOR_1');
        expect(response.owner?.title, 'Sample Creator');
        expect(response.description, 'Video Description text');
        service.close();
      },
    );

    test(
      'getWatchNext raises when neither videoId nor continuation is given',
      () async {
        final service = YoutubeService(
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        );
        await expectLater(
          service.getWatchNext(),
          throwsA(isA<YpiJsonException>()),
        );
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

    test('browseChannel posts to browse and returns lockup items', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/youtubei/v1/browse');
        final body = json.decode(request.body) as Map<String, dynamic>;
        expect(body['browseId'], 'UC_CHANNEL_1');
        expect(body['params'], 'EgZ2aWRlb3PyBgQKAjoA');
        expect(body['continuation'], isNull);
        expect(body['context'], isA<Map<String, dynamic>>());
        return http.Response(
          json.encode({
            'header': {
              'pageHeaderRenderer': {'pageTitle': 'Channel One'},
            },
            'metadata': {
              'channelMetadataRenderer': {'externalId': 'UC_CHANNEL_1'},
            },
            'contents': {
              'twoColumnBrowseResultsRenderer': {
                'tabs': [
                  {
                    'tabRenderer': {
                      'title': '视频',
                      'selected': true,
                      'content': {
                        'richGridRenderer': {
                          'contents': [
                            {
                              'richItemRenderer': {
                                'content': {
                                  'lockupViewModel': {
                                    'contentId': 'PXC_ONE',
                                    'contentType': 'LOCKUP_CONTENT_TYPE_VIDEO',
                                    'metadata': {
                                      'lockupMetadataViewModel': {
                                        'title': {'content': 'Video One'},
                                      },
                                    },
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
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = YoutubeService(httpClient: mockClient);
      final response = await service.browseChannel(
        browseId: 'UC_CHANNEL_1',
        params: 'EgZ2aWRlb3PyBgQKAjoA',
      );
      expect(response.header?.channelId, 'UC_CHANNEL_1');
      expect(response.header?.title, 'Channel One');
      expect(response.items.single.contentId, 'PXC_ONE');
      expect(response.items.single.title, 'Video One');
      service.close();
    });

    test(
      'browseChannel pages with a continuation instead of a browseId',
      () async {
        final mockClient = MockClient((request) async {
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['continuation'], 'TOKEN_1');
          expect(body['browseId'], isNull);
          return http.Response(
            json.encode({
              'onResponseReceivedActions': [
                {
                  'appendContinuationItemsAction': {
                    'continuationItems': [
                      {
                        'richItemRenderer': {
                          'content': {
                            'lockupViewModel': {
                              'contentId': 'PXC_PAGE2',
                              'contentType': 'LOCKUP_CONTENT_TYPE_VIDEO',
                              'metadata': {
                                'lockupMetadataViewModel': {
                                  'title': {'content': 'Video Two'},
                                },
                              },
                            },
                          },
                        },
                      },
                      {
                        'continuationItemRenderer': {
                          'continuationEndpoint': {
                            'continuationCommand': {'token': 'TOKEN_2'},
                          },
                        },
                      },
                    ],
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = YoutubeService(httpClient: mockClient);
        final response = await service.browseChannel(continuation: 'TOKEN_1');
        expect(response.items.single.contentId, 'PXC_PAGE2');
        expect(response.continuationToken, 'TOKEN_2');
        service.close();
      },
    );

    test(
      'browseChannel raises when neither browseId nor continuation is given',
      () async {
        final service = YoutubeService(
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        );
        await expectLater(
          service.browseChannel(),
          throwsA(isA<YpiJsonException>()),
        );
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
      networkService.close();
    });

    test(
      'browsePlaylist posts to browse with VL prefix and returns items',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/youtubei/v1/browse');
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['browseId'], 'VLPL_TEST_123');
          expect(body['continuation'], isNull);
          expect(body['context'], isA<Map<String, dynamic>>());
          return http.Response(
            json.encode({
              'header': {
                'playlistHeaderRenderer': {
                  'playlistId': 'PL_TEST_123',
                  'title': {'simpleText': 'Test Playlist'},
                  'numVideosText': {'simpleText': '10 videos'},
                },
              },
              'contents': {
                'twoColumnBrowseResultsRenderer': {
                  'tabs': [
                    {
                      'tabRenderer': {
                        'content': {
                          'sectionListRenderer': {
                            'contents': [
                              {
                                'itemSectionRenderer': {
                                  'contents': [
                                    {
                                      'playlistVideoListRenderer': {
                                        'contents': [
                                          {
                                            'playlistVideoRenderer': {
                                              'videoId': 'VIDEO_1',
                                              'title': {
                                                'runs': [
                                                  {
                                                    'text':
                                                        'Playlist Video One',
                                                  },
                                                ],
                                              },
                                              'lengthText': {
                                                'simpleText': '05:00',
                                              },
                                            },
                                          },
                                        ],
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
                  ],
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = YoutubeService(httpClient: mockClient);
        final response = await service.browsePlaylist(
          playlistId: 'PL_TEST_123',
        );
        expect(response.header?.playlistId, 'PL_TEST_123');
        expect(response.header?.title, 'Test Playlist');
        expect(response.header?.videoCountText, '10 videos');
        expect(response.items.single.videoId, 'VIDEO_1');
        expect(response.items.single.title, 'Playlist Video One');
        service.close();
      },
    );

    test(
      'browsePlaylist echoes the sanitised id when the header omits it',
      () async {
        final mockClient = MockClient((request) async {
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['browseId'], 'VLPL_TEST_123');
          return http.Response(
            json.encode({
              'header': {
                'playlistHeaderRenderer': {
                  'title': {'simpleText': 'Test Playlist'},
                  'numVideosText': {'simpleText': '10 videos'},
                },
              },
              'contents': {
                'twoColumnBrowseResultsRenderer': {
                  'tabs': [
                    {
                      'tabRenderer': {
                        'content': {
                          'sectionListRenderer': {
                            'contents': [
                              {
                                'itemSectionRenderer': {
                                  'contents': [
                                    {
                                      'playlistVideoListRenderer': {
                                        'contents': [
                                          {
                                            'playlistVideoRenderer': {
                                              'videoId': 'VIDEO_1',
                                              'title': {
                                                'runs': [
                                                  {
                                                    'text':
                                                        'Playlist Video One',
                                                  },
                                                ],
                                              },
                                              'lengthText': {
                                                'simpleText': '05:00',
                                              },
                                            },
                                          },
                                        ],
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
                  ],
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = YoutubeService(httpClient: mockClient);
        final response = await service.browsePlaylist(
          playlistId: 'PL_TEST_123\n',
        );
        expect(response.header?.playlistId, 'PL_TEST_123');
        service.close();
      },
    );

    test(
      'browsePlaylist pages with a continuation instead of a playlistId',
      () async {
        final mockClient = MockClient((request) async {
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['continuation'], 'PLAYLIST_TOKEN_1');
          expect(body['browseId'], isNull);
          return http.Response(
            json.encode({
              'onResponseReceivedActions': [
                {
                  'appendContinuationItemsAction': {
                    'continuationItems': [
                      {
                        'playlistVideoRenderer': {
                          'videoId': 'VIDEO_PAGE_2',
                          'title': {
                            'runs': [
                              {'text': 'Video Page Two'},
                            ],
                          },
                        },
                      },
                      {
                        'continuationItemRenderer': {
                          'continuationEndpoint': {
                            'continuationCommand': {
                              'token': 'PLAYLIST_TOKEN_2',
                            },
                          },
                        },
                      },
                    ],
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = YoutubeService(httpClient: mockClient);
        final response = await service.browsePlaylist(
          continuation: 'PLAYLIST_TOKEN_1',
        );
        expect(response.items.single.videoId, 'VIDEO_PAGE_2');
        expect(response.continuationToken, 'PLAYLIST_TOKEN_2');
        service.close();
      },
    );

    test(
      'browsePlaylist raises when neither playlistId nor continuation is given',
      () async {
        final service = YoutubeService(
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        );
        await expectLater(
          service.browsePlaylist(),
          throwsA(isA<YpiJsonException>()),
        );
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

    test('browseChannel posts to browse and returns lockup items', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/youtubei/v1/browse');
        final body = json.decode(request.body) as Map<String, dynamic>;
        expect(body['browseId'], 'UC_CHANNEL_1');
        expect(body['params'], 'EgZ2aWRlb3PyBgQKAjoA');
        expect(body['continuation'], isNull);
        expect(body['context'], isA<Map<String, dynamic>>());
        return http.Response(
          json.encode({
            'header': {
              'pageHeaderRenderer': {'pageTitle': 'Channel One'},
            },
            'metadata': {
              'channelMetadataRenderer': {'externalId': 'UC_CHANNEL_1'},
            },
            'contents': {
              'twoColumnBrowseResultsRenderer': {
                'tabs': [
                  {
                    'tabRenderer': {
                      'title': '视频',
                      'selected': true,
                      'content': {
                        'richGridRenderer': {
                          'contents': [
                            {
                              'richItemRenderer': {
                                'content': {
                                  'lockupViewModel': {
                                    'contentId': 'PXC_ONE',
                                    'contentType': 'LOCKUP_CONTENT_TYPE_VIDEO',
                                    'metadata': {
                                      'lockupMetadataViewModel': {
                                        'title': {'content': 'Video One'},
                                      },
                                    },
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
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = YoutubeService(httpClient: mockClient);
      final response = await service.browseChannel(
        browseId: 'UC_CHANNEL_1',
        params: 'EgZ2aWRlb3PyBgQKAjoA',
      );
      expect(response.header?.channelId, 'UC_CHANNEL_1');
      expect(response.header?.title, 'Channel One');
      expect(response.items.single.contentId, 'PXC_ONE');
      expect(response.items.single.title, 'Video One');
      service.close();
    });

    test(
      'browseChannel pages with a continuation instead of a browseId',
      () async {
        final mockClient = MockClient((request) async {
          final body = json.decode(request.body) as Map<String, dynamic>;
          expect(body['continuation'], 'TOKEN_1');
          expect(body['browseId'], isNull);
          return http.Response(
            json.encode({
              'onResponseReceivedActions': [
                {
                  'appendContinuationItemsAction': {
                    'continuationItems': [
                      {
                        'richItemRenderer': {
                          'content': {
                            'lockupViewModel': {
                              'contentId': 'PXC_PAGE2',
                              'contentType': 'LOCKUP_CONTENT_TYPE_VIDEO',
                              'metadata': {
                                'lockupMetadataViewModel': {
                                  'title': {'content': 'Video Two'},
                                },
                              },
                            },
                          },
                        },
                      },
                      {
                        'continuationItemRenderer': {
                          'continuationEndpoint': {
                            'continuationCommand': {'token': 'TOKEN_2'},
                          },
                        },
                      },
                    ],
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = YoutubeService(httpClient: mockClient);
        final response = await service.browseChannel(continuation: 'TOKEN_1');
        expect(response.items.single.contentId, 'PXC_PAGE2');
        expect(response.continuationToken, 'TOKEN_2');
        service.close();
      },
    );

    test(
      'browseChannel raises when neither browseId nor continuation is given',
      () async {
        final service = YoutubeService(
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        );
        await expectLater(
          service.browseChannel(),
          throwsA(isA<YpiJsonException>()),
        );
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
      networkService.close();
    });
  });
  group('YoutubeService.getComments', () {
    test('posts to /next with the trimmed continuation', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/youtubei/v1/next'));
        final body = json.decode(request.body) as Map<String, dynamic>;
        // continuation 必须先 trim 再发出，不能带调用方传入的空白。
        expect(body['continuation'], equals('TOKEN_123'));
        return http.Response(
          json.encode({
            'onResponseReceivedEndpoints': <dynamic>[
              {
                'appendContinuationItemsAction': {
                  'continuationItems': <dynamic>[
                    {
                      'commentThreadRenderer': {
                        'comment': {
                          'commentRenderer': {
                            'commentId': 'C1',
                            'contentText': {'simpleText': 'hi'},
                          },
                        },
                      },
                    },
                  ],
                },
              },
            ],
          }),
          200,
        );
      });
      final service = YoutubeService(httpClient: mockClient);
      addTearDown(service.close);

      await service.getComments('  TOKEN_123  ');

    });

    test('rejects an empty continuation before issuing a request', () async {
      var called = false;
      final mockClient = MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      });
      final service = YoutubeService(httpClient: mockClient);
      addTearDown(service.close);

      await expectLater(
        service.getComments('   '),
        throwsA(isA<YpiJsonException>()),
      );
      expect(called, isFalse, reason: '空 continuation 不该发请求');
    });
  });

}

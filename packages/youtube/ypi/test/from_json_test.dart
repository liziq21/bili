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

  test('an unrecognized tab renderer does not discard the other tabs', () {
    final response = NetworkYouTubeBrowseResponse.fromJson(<String, dynamic>{
      'metadata': <String, dynamic>{
        'channelMetadataRenderer': <String, dynamic>{'externalId': 'UC_X'},
      },
      'contents': <String, dynamic>{
        'twoColumnBrowseResultsRenderer': <String, dynamic>{
          'tabs': <Map<String, dynamic>>[
            <String, dynamic>{'someFutureTabRenderer': <String, dynamic>{}},
            <String, dynamic>{
              'tabRenderer': <String, dynamic>{
                'title': '视频',
                'content': <String, dynamic>{
                  'richGridRenderer': <String, dynamic>{
                    'contents': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'richItemRenderer': <String, dynamic>{
                          'content': <String, dynamic>{
                            'lockupViewModel': <String, dynamic>{
                              'contentId': 'PXC_SURVIVES',
                              'contentType': 'LOCKUP_CONTENT_TYPE_VIDEO',
                              'metadata': <String, dynamic>{
                                'lockupMetadataViewModel': <String, dynamic>{
                                  'title': <String, dynamic>{'content': 'Kept'},
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
    });

    // YouTube introduces new tab shapes; one of them must not take the video
    // entries the remaining tabs already yielded down with it.
    expect(response.tabs.map((tab) => tab.title), ['视频']);
    expect(response.items.map((item) => item.contentId), ['PXC_SURVIVES']);
  });
  test(
    'a lockup without a content ID is dropped, and its neighbours survive',
    () {
      Map<String, dynamic> lockup(String? contentId) => <String, dynamic>{
        'lockupViewModel': <String, dynamic>{
          'contentId': ?contentId,
          'metadata': <String, dynamic>{
            'lockupMetadataViewModel': <String, dynamic>{
              'title': <String, dynamic>{'content': 'Video $contentId'},
            },
          },
        },
      };

      final response = NetworkYouTubeBrowseResponse.fromJson(<String, dynamic>{
        'metadata': <String, dynamic>{
          'channelMetadataRenderer': <String, dynamic>{'externalId': 'UC_X'},
        },
        'contents': <String, dynamic>{
          'twoColumnBrowseResultsRenderer': <String, dynamic>{
            'tabs': <Map<String, dynamic>>[
              <String, dynamic>{
                'tabRenderer': <String, dynamic>{
                  'title': '视频',
                  'content': <String, dynamic>{
                    'richGridRenderer': <String, dynamic>{
                      'contents': <Map<String, dynamic>>[
                        <String, dynamic>{
                          'richItemRenderer': <String, dynamic>{
                            'content': lockup('PXC_KEEP_FIRST'),
                          },
                        },
                        <String, dynamic>{
                          'richItemRenderer': <String, dynamic>{
                            'content': lockup(null),
                          },
                        },
                        <String, dynamic>{
                          'richItemRenderer': <String, dynamic>{
                            'content': lockup('PXC_KEEP_LAST'),
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
      });

      // An empty ID would leave the caller unable to open or deduplicate the
      // entry, so the entry is dropped and collection continues.
      expect(response.items.map((item) => item.contentId), [
        'PXC_KEEP_FIRST',
        'PXC_KEEP_LAST',
      ]);
    },
  );

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

  test('parses the real watch next fixture into typed video details', () {
    final response = NetworkYouTubeWatchNextResponse.fromJson(
      loadFixtureMap('watch_next.json'),
    );
    expect(response.videoId, 'dQw4w9WgXcQ');
    expect(response.title, contains('Rick Astley'));
    expect(response.viewCountText, isNotNull);
    expect(response.publishedTimeText, isNotNull);
    expect(response.owner?.channelId, 'UCuAXFkgsw1L7xaCfnd5JJOw');
    expect(response.owner?.title, 'Rick Astley');
    expect(response.description, isNotNull);
  });

  test('watch next missing videoId throws FormatException', () {
    expect(
      () => NetworkYouTubeWatchNextResponse.fromJson(<String, dynamic>{
        'contents': <String, dynamic>{},
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('watch next with a usable contents list but no title throws', () {
    // 失效/受限视频的响应形态：HTTP 200、results.results.contents 非空，
    // 但里面没有 videoPrimaryInfoRenderer。兜底的 videoId 会让非空检查通过，
    // 于是返回一个标题与作者全 null 的「成功」响应。
    expect(
      () => NetworkYouTubeWatchNextResponse.fromJson(<String, dynamic>{
        'contents': <String, dynamic>{
          'twoColumnWatchNextResults': <String, dynamic>{
            'results': <String, dynamic>{
              'results': <String, dynamic>{
                'contents': <dynamic>[
                  <String, dynamic>{
                    'videoSecondaryInfoRenderer': <String, dynamic>{
                      'owner': <String, dynamic>{
                        'videoOwnerRenderer': <String, dynamic>{
                          'navigationEndpoint': <String, dynamic>{
                            'browseEndpoint': <String, dynamic>{
                              'browseId': 'UCuAXFkgsw1L7xaCfnd5JJOw',
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
      }, requestedVideoId: 'dQw4w9WgXcQ'),
      throwsA(isA<FormatException>()),
    );
  });

  test('watch next parses items from a continuation response', () {
    // 续页结构与首屏完全不同：条目在
    // onResponseReceivedActions[].appendContinuationItemsAction.continuationItems。
    // 只读首屏路径的话，续页响应会被当成「没有内容」。
    final response = NetworkYouTubeWatchNextResponse.fromJson(<String, dynamic>{
      'onResponseReceivedActions': <dynamic>[
        <String, dynamic>{
          'appendContinuationItemsAction': <String, dynamic>{
            'continuationItems': <dynamic>[
              <String, dynamic>{
                'videoPrimaryInfoRenderer': <String, dynamic>{
                  'title': <String, dynamic>{
                    'runs': <dynamic>[
                      <String, dynamic>{'text': 'Continued Title'},
                    ],
                  },
                  'viewCount': <String, dynamic>{
                    'videoViewCountRenderer': <String, dynamic>{
                      'viewCount': <String, dynamic>{'simpleText': '1,000次观看'},
                    },
                  },
                },
              },
              <String, dynamic>{
                'videoSecondaryInfoRenderer': <String, dynamic>{
                  'owner': <String, dynamic>{
                    'videoOwnerRenderer': <String, dynamic>{
                      'navigationEndpoint': <String, dynamic>{
                        'browseEndpoint': <String, dynamic>{
                          'browseId': 'UCuAXFkgsw1L7xaCfnd5JJOw',
                        },
                      },
                      'title': <String, dynamic>{
                        'runs': <dynamic>[
                          <String, dynamic>{'text': 'Continued Owner'},
                        ],
                      },
                    },
                  },
                  'attributedDescription': <String, dynamic>{
                    'content': 'Continued description',
                  },
                },
              },
            ],
          },
        },
      ],
    }, requestedVideoId: 'dQw4w9WgXcQ');
    expect(response.title, 'Continued Title');
    expect(response.viewCountText, '1,000次观看');
    expect(response.owner?.title, 'Continued Owner');
    expect(response.description, 'Continued description');
  });

  test('watch next reads an ERROR alert reason expressed as runs', () {
    // alert 文本有两种形态。只读 simpleText 的实现，在 runs 形态下 reason 会
    // 退化成 'InnerTube alert: ERROR'，具体原因丢掉。
    expect(
      () => NetworkYouTubeWatchNextResponse.fromJson(<String, dynamic>{
        'alerts': <dynamic>[
          <String, dynamic>{
            'alertRenderer': <String, dynamic>{
              'type': 'ERROR',
              'text': <String, dynamic>{
                'runs': <dynamic>[
                  <String, dynamic>{'text': 'Video is unavailable'},
                ],
              },
            },
          },
        ],
      }),
      throwsA(
        isA<YpiInnerTubeException>().having(
          (e) => e.reason,
          'reason',
          'Video is unavailable',
        ),
      ),
    );
  });

  test('parses the real video player fixture into typed player response', () {
    final response = NetworkYouTubePlayerResponse.fromJson(
      loadFixtureMap('player.json'),
    );
    expect(response.videoId, 'dQw4w9WgXcQ');
    expect(response.playabilityStatus?.status, 'UNPLAYABLE');
    expect(response.playabilityStatus?.reason, isNotNull);
    expect(response.videoDetails?.videoId, 'dQw4w9WgXcQ');
    expect(response.videoDetails?.title, contains('Rick Astley'));
    expect(response.videoDetails?.author, 'Rick Astley');
    expect(response.videoDetails?.channelId, 'UCuAXFkgsw1L7xaCfnd5JJOw');
    expect(response.videoDetails?.lengthSeconds, '213');
    expect(response.microformat?.category, 'Music');
    expect(response.microformat?.publishDate, isNotNull);
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

  test('parses the real comments fixture into typed comment threads', () {
    final response = NetworkYouTubeCommentsResponse.fromJson(
      loadFixtureMap('comments.json'),
    );
    expect(response.headerCountText, isNotNull);
    expect(response.headerCountText, isNotEmpty);
    expect(response.items, isNotEmpty);

    final first = response.items.first;
    expect(first.commentId, isNotEmpty);
    expect(first.text, isNotNull);
    expect(first.text, isNotEmpty);
    expect(first.author?.displayName, isNotNull);
    expect(first.author?.channelId, isNotNull);
    expect(first.author?.avatar?.thumbnails, isNotEmpty);
    expect(first.publishedTimeText, isNotNull);
    expect(first.likeCountText, isNotNull);

    expect(response.continuationToken, isNotNull);
    expect(response.continuationToken, isNotEmpty);
  });

  test('parses legacy commentRenderer structure in commentThreadRenderer', () {
    final response = NetworkYouTubeCommentsResponse.fromJson({
      'onResponseReceivedEndpoints': [
        {
          'reloadContinuationItemsCommand': {
            'continuationItems': [
              {
                'commentsHeaderRenderer': {
                  'countText': {'simpleText': '100'},
                },
              },
              {
                'commentThreadRenderer': {
                  'comment': {
                    'commentRenderer': {
                      'commentId': 'LEGACY_COMMENT_1',
                      'authorText': {'simpleText': 'Legacy Author'},
                      'authorEndpoint': {
                        'browseEndpoint': {'browseId': 'UC_LEGACY_1'},
                      },
                      'authorThumbnail': {
                        'thumbnails': [
                          {'url': 'https://yt.com/avatar.jpg'},
                        ],
                      },
                      'contentText': {'simpleText': 'Legacy Comment Text'},
                      'publishedTimeText': {'simpleText': '2 hours ago'},
                      'voteCount': {'simpleText': '42'},
                      'replyCount': 5,
                    },
                  },
                },
              },
            ],
          },
        },
      ],
    });

    expect(response.headerCountText, '100');
    expect(response.items, hasLength(1));
    final comment = response.items.single;
    expect(comment.commentId, 'LEGACY_COMMENT_1');
    expect(comment.author?.displayName, 'Legacy Author');
    expect(comment.author?.channelId, 'UC_LEGACY_1');
    expect(
      comment.author?.avatar?.thumbnails.first.url,
      'https://yt.com/avatar.jpg',
    );
    expect(comment.text, 'Legacy Comment Text');
    expect(comment.publishedTimeText, '2 hours ago');
    expect(comment.likeCountText, '42');
    expect(comment.replyCount, 5);
  });
  test('rejects a comments response with no continuation endpoints', () {
    // 响应结构变化时端点会整个消失。静默返回空列表会让调用方把
    // 「解析器不认识这个响应」误当成「视频没有评论」。
    expect(
      () => NetworkYouTubeCommentsResponse.fromJson(<String, dynamic>{
        'responseContext': <String, dynamic>{},
        'onResponseReceivedEndpoints': <dynamic>[],
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'takes the comments continuation token only from the comments section',
    () {
      // 非评论区段排在前面且同样带 continuationItemRenderer。旧条件
      // `targetId == 'comments-section' || commentsContinuationToken == null`
      // 会让前者的令牌抢先写入，而 `??=` 使评论区令牌无法覆盖它。
      Map<String, dynamic> section(String key, String name, String token) =>
          <String, dynamic>{
            'itemSectionRenderer': <String, dynamic>{
              key: name,
              'contents': <dynamic>[
                <String, dynamic>{
                  'continuationItemRenderer': <String, dynamic>{
                    'continuationEndpoint': <String, dynamic>{
                      'continuationCommand': <String, dynamic>{'token': token},
                    },
                  },
                },
              ],
            },
          };

      final json = <String, dynamic>{
        'currentVideoEndpoint': <String, dynamic>{
          'watchEndpoint': <String, dynamic>{'videoId': 'VIDEO_ID'},
        },
        'contents': <String, dynamic>{
          'twoColumnWatchNextResults': <String, dynamic>{
            'results': <String, dynamic>{
              'results': <String, dynamic>{
                'contents': <dynamic>[
                  <String, dynamic>{
                    'videoPrimaryInfoRenderer': <String, dynamic>{
                      'title': <String, dynamic>{
                        'runs': <dynamic>[
                          <String, dynamic>{'text': 'A title'},
                        ],
                      },
                    },
                  },
                  section(
                    'sectionId',
                    'related-items-section',
                    'RELATED_SECTION_TOKEN',
                  ),
                  section(
                    'targetId',
                    'comments-section',
                    'COMMENTS_SECTION_TOKEN',
                  ),
                ],
              },
            },
          },
        },
      };

      final response = NetworkYouTubeWatchNextResponse.fromJson(json);

      expect(response.commentsContinuationToken, 'COMMENTS_SECTION_TOKEN');
    },
  );
}

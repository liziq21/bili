import 'dart:async';

import 'package:data/data.dart';
import 'package:flutter/widgets.dart' hide Page;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:model/model.dart';
import 'package:test/test.dart';
import 'package:youtube/src/youtube_utils.dart';
import 'package:youtube/youtube.dart';

void main() {
  group('YouTube Package Initializer Tests', () {
    test('YouTube facade creates RemoteDataSources with sourceId "youtube" and exposes sort & filter options', () {
      final youtube = YouTube();

      final videoDS = youtube.videoSearchDataSource;
      final creatorDS = youtube.creatorProfileSearchDataSource;
      final suggestDS = youtube.searchSuggestDataSource;

      expect(videoDS, isA<VideoSearchRemoteDataSource>());
      expect(creatorDS, isA<CreatorProfileSearchRemoteDataSource>());
      expect(suggestDS, isA<SearchSuggestRemoteDataSource>());

      expect(videoDS.sourceId, equals('youtube'));
      expect(creatorDS.sourceId, equals('youtube'));
      expect(suggestDS.sourceId, equals('youtube'));

      expect(videoDS.sortOptions, isNotEmpty);
      expect(videoDS.sortOptions.length, equals(4));

      expect(videoDS.filters, isNotEmpty);
      expect(videoDS.filters.length, equals(3));
      expect(youtube.videoFeedDataSources, isEmpty);

      unawaited(youtube.close());
    });

    test('YouTube respects static YouTube.client when httpClient parameter is null', () async {
      var clientUsed = false;
      final mockClient = MockClient((_) async {
        clientUsed = true;
        return http.Response('unavailable', 503);
      });

      YouTube.client = mockClient;
      addTearDown(() => YouTube.client = null);

      final youtube = YouTube();
      final ds = youtube.videoSearchDataSource;
      await ds.searchVideoWithOptions(
        const SearchQuery(query: 'test', pageKey: 1),
      );

      expect(clientUsed, isTrue);
      await youtube.close();
    });

    test('Remote data sources sanitize error handling and do not leak stack traces into Result.error', () async {
      final youtube = YouTube(
        httpClient: MockClient((_) async => http.Response('unavailable', 503)),
      );

      final ds = youtube.videoSearchDataSource;
      final videoRes = await ds.searchVideoWithOptions(
        SearchQuery(
          query: 'test',
          pageKey: 1,
          filters: const [
            SingleFilterGroup(
              key: 'upload_date',
              label: 'invalid',
              options: [YoutubeUploadDateFilterOption.today],
              selection: YoutubeUploadDateFilterOption.today,
            ),
          ],
        ),
      );
      expect(videoRes, isA<Result<Page<VideoModel>>>());
      expect(videoRes, isA<Error>());
      if (videoRes is Error) {
        expect(videoRes.toString(), isNot(contains('\n#0')));
      }

      await youtube.close();
    });

    test('Search sort and filter options localize correctly in Chinese (zh) and English (en)', () {
      final zh = lookupYoutubeLocalizations(const Locale('zh'));
      final en = lookupYoutubeLocalizations(const Locale('en'));

      // Sort option localization
      expect(YoutubeSearchSort.relevance.labelWithL10n(zh), equals('相关性'));
      expect(
        YoutubeSearchSort.relevance.labelWithL10n(en),
        equals('Relevance'),
      );

      expect(YoutubeSearchSort.uploadDate.labelWithL10n(zh), equals('上传时间'));
      expect(
        YoutubeSearchSort.uploadDate.labelWithL10n(en),
        equals('Upload date'),
      );

      expect(YoutubeSearchSort.viewCount.labelWithL10n(zh), equals('播放量'));
      expect(
        YoutubeSearchSort.viewCount.labelWithL10n(en),
        equals('View count'),
      );

      expect(YoutubeSearchSort.rating.labelWithL10n(zh), equals('评分'));
      expect(YoutubeSearchSort.rating.labelWithL10n(en), equals('Rating'));

      // Filter option localization
      expect(
        YoutubeUploadDateFilterOption.today.labelWithL10n(zh),
        equals('今天'),
      );
      expect(
        YoutubeUploadDateFilterOption.today.labelWithL10n(en),
        equals('Today'),
      );

      expect(
        YoutubeDurationFilterOption.under4Minutes.labelWithL10n(zh),
        equals('4分钟以下'),
      );
      expect(
        YoutubeDurationFilterOption.under4Minutes.labelWithL10n(en),
        equals('Under 4 minutes'),
      );

      expect(YoutubeFeatureFilterOption.live.labelWithL10n(zh), equals('直播'));
      expect(YoutubeFeatureFilterOption.live.labelWithL10n(en), equals('Live'));

      // Filter group title localization
      const uploadGroup = YoutubeUploadDateFilterGroup();
      const durationGroup = YoutubeDurationFilterGroup();
      const featureGroup = YoutubeFeatureFilterGroup();

      expect(uploadGroup.labelWithL10n(zh), equals('上传时间'));
      expect(uploadGroup.labelWithL10n(en), equals('Upload date'));

      expect(durationGroup.labelWithL10n(zh), equals('视频时长'));
      expect(durationGroup.labelWithL10n(en), equals('Duration'));

      expect(featureGroup.labelWithL10n(zh), equals('功能特性'));
      expect(featureGroup.labelWithL10n(en), equals('Features'));
    });

    test('searchSuggestDataSource sanitizes control characters and returns empty list on blank queries', () async {
      var requestMade = false;
      final youtube = YouTube(
        httpClient: MockClient((request) async {
          requestMade = true;
          expect(request.url.queryParameters['q'], equals('flutter'));
          return http.Response(
            '["flutter", [["flutter tutorial", 0], ["flutter course", 0]]]',
            200,
            headers: {'content-type': 'text/plain'},
          );
        }),
      );

      final suggestDS = youtube.searchSuggestDataSource;

      // Blank or control-character-only query fast returns Result.ok([])
      final blankResult = await suggestDS.getSuggests('   \r\n\x00 ');
      expect(blankResult, isA<Ok<List<String>>>());
      expect((blankResult as Ok<List<String>>).value, isEmpty);
      expect(requestMade, isFalse);

      // Query with control characters sanitizes query input and suggestion outputs
      final result = await suggestDS.getSuggests('flut\r\nter\x00');
      expect(requestMade, isTrue);
      expect(result, isA<Ok<List<String>>>());
      expect(
        (result as Ok<List<String>>).value,
        equals(['flutter tutorial', 'flutter course']),
      );

      await youtube.close();
    });

    test('videoSearchDataSource and creatorProfileSearchDataSource sanitize control characters and handle blank queries', () async {
      var videoRequestMade = false;
      var creatorRequestMade = false;

      final youtube = YouTube(
        httpClient: MockClient((request) async {
          if (request.url.path.contains('/search')) {
            videoRequestMade = true;
            creatorRequestMade = true;
          }
          return http.Response('{}', 200);
        }),
      );

      final videoDS = youtube.videoSearchDataSource;
      final creatorDS = youtube.creatorProfileSearchDataSource;

      // Blank query fast-returns empty Page without making HTTP request
      final blankVideoRes = await videoDS.searchVideo('  \r\n\x00  ');
      expect(blankVideoRes, isA<Ok<Page<VideoModel>>>());
      expect((blankVideoRes as Ok<Page<VideoModel>>).value.data, isEmpty);
      expect(videoRequestMade, isFalse);

      final blankCreatorRes = await creatorDS.searchCreatorProfile('  \x1f  ');
      expect(blankCreatorRes, isA<Ok<Page<CreatorProfile>>>());
      expect((blankCreatorRes as Ok<Page<CreatorProfile>>).value.data, isEmpty);
      expect(creatorRequestMade, isFalse);

      await youtube.close();
    });

    test('normalizeYoutubeUrl tests', () {
      expect(normalizeYoutubeUrl(null), isNull);
      expect(normalizeYoutubeUrl(''), isNull);
      expect(
        normalizeYoutubeUrl('//yt3.googleusercontent.com/pic.jpg'),
        equals('https://yt3.googleusercontent.com/pic.jpg'),
      );
      expect(
        normalizeYoutubeUrl('http://yt3.googleusercontent.com/pic.jpg'),
        equals('https://yt3.googleusercontent.com/pic.jpg'),
      );
      expect(
        normalizeYoutubeUrl('https://yt3.googleusercontent.com/pic.jpg'),
        equals('https://yt3.googleusercontent.com/pic.jpg'),
      );
    });

    test('videoSearchDataSource and creatorProfileSearchDataSource normalize thumbnail URLs in DTOs', () async {
      final jsonResponse = '''
{
  "contents": {
    "twoColumnSearchResultsRenderer": {
      "primaryContents": {
        "sectionListRenderer": {
          "contents": [
            {
              "itemSectionRenderer": {
                "contents": [
                  {
                    "videoRenderer": {
                      "videoId": "abc12345",
                      "title": {"runs": [{"text": "Sample Video"}]},
                      "thumbnail": {
                        "thumbnails": [
                          {"url": "//yt3.googleusercontent.com/thumb.jpg", "width": 120, "height": 90}
                        ]
                      }
                    }
                  },
                  {
                    "channelRenderer": {
                      "channelId": "UC123456",
                      "title": {"simpleText": "Sample Channel"},
                      "thumbnail": {
                        "thumbnails": [
                          {"url": "http://yt3.googleusercontent.com/avatar.jpg", "width": 88, "height": 88}
                        ]
                      }
                    }
                  }
                ]
              }
            }
          ]
        }
      }
    }
  }
}
''';

      final youtube = YouTube(
        httpClient: MockClient((_) async => http.Response(jsonResponse, 200)),
      );

      final videoDS = youtube.videoSearchDataSource;
      final videoRes = await videoDS.searchVideo('sample');
      expect(videoRes, isA<Ok<Page<VideoModel>>>());
      final videos = (videoRes as Ok<Page<VideoModel>>).value.data;
      expect(videos, hasLength(1));
      expect(
        videos.first.thumbnailUrl,
        equals('https://yt3.googleusercontent.com/thumb.jpg'),
      );

      final creatorDS = youtube.creatorProfileSearchDataSource;
      final creatorRes = await creatorDS.searchCreatorProfile('sample');
      expect(creatorRes, isA<Ok<Page<CreatorProfile>>>());
      final profiles = (creatorRes as Ok<Page<CreatorProfile>>).value.data;
      expect(profiles, hasLength(1));
      expect(
        profiles.first.thumbnailUrl,
        equals('https://yt3.googleusercontent.com/avatar.jpg'),
      );

      await youtube.close();
    });
  });
}

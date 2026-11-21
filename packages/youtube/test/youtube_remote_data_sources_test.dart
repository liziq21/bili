import 'dart:convert';
import 'dart:io';

import 'package:data/data.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:model/model.dart';
import 'package:test/test.dart';
import 'package:youtube/youtube.dart';

String _fixture(String name) {
  for (final candidate in [
    File('ypi/testing/$name'),
    File('packages/youtube/ypi/testing/$name'),
  ]) {
    if (candidate.existsSync()) return candidate.readAsStringSync();
  }
  fail('Fixture $name not found');
}

http.Response _jsonResponse(String body, {int statusCode = 200}) =>
    http.Response(
      body,
      statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  group('YouTubeVideoDetailRemoteDataSource', () {
    test('maps watch next into a VideoDetail', () async {
      final youtube = YouTube(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/youtubei/v1/next');
          return _jsonResponse(_fixture('watch_next.json'));
        }),
      );

      final result = await youtube.videoDetailDataSource.getVideoDetail(
        'dQw4w9WgXcQ',
      );

      expect(result, isA<Success<VideoDetail, Exception>>());
      final detail = (result as Success<VideoDetail, Exception>).success;
      expect(detail.video.id, 'dQw4w9WgXcQ');
      expect(detail.video.title, contains('Never Gonna Give You Up'));
      expect(detail.video.url, contains('watch?v=dQw4w9WgXcQ'));
      expect(detail.video.thumbnailUrl, contains('i.ytimg.com/vi/dQw4w9WgXcQ'));
      expect(detail.video.viewCount, 1822486005);
      expect(detail.video.uploadDate, isNotNull);
      expect(detail.video.desc, isNotEmpty);
      expect(detail.creator?.id, 'UCuAXFkgsw1L7xaCfnd5JJOw');
      expect(detail.creator?.subscribers, 4550000);

      await youtube.close();
    });

    test('returns an error when the endpoint rejects the request', () async {
      final youtube = YouTube(
        httpClient: MockClient(
          (_) async => _jsonResponse('unavailable', statusCode: 503),
        ),
      );

      final result = await youtube.videoDetailDataSource.getVideoDetail(
        'dQw4w9WgXcQ',
      );

      expect(result, isA<Error<VideoDetail, Exception>>());
      await youtube.close();
    });
  });

  group('YouTubeCreatorProfileSearchRemoteDataSource', () {
    test('resolves a channel ID through the channel browse endpoint', () async {
      final youtube = YouTube(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/youtubei/v1/browse');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['browseId'], 'UCuAXFkgsw1L7xaCfnd5JJOw');
          return _jsonResponse(_fixture('browse.json'));
        }),
      );

      final result = await youtube.creatorProfileSearchDataSource
          .searchCreatorProfile('UCuAXFkgsw1L7xaCfnd5JJOw');

      expect(result, isA<Success<Page<CreatorProfile>, Exception>>());
      final profile = (result as Success<Page<CreatorProfile>, Exception>)
          .success
          .data
          .single;
      expect(profile.id, 'UCuAXFkgsw1L7xaCfnd5JJOw');
      expect(profile.name, 'Rick Astley');
      expect(profile.description, isNotEmpty);
      expect(profile.thumbnailUrl, isNotNull);

      await youtube.close();
    });
  });

  group('YouTubeVideoCommentRemoteDataSource', () {
    test('loads comments with the watch next continuation token', () async {
      var nextRequestCount = 0;
      final youtube = YouTube(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/youtubei/v1/next');
          nextRequestCount++;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (body.containsKey('videoId')) {
            expect(body['videoId'], 'dQw4w9WgXcQ');
            return _jsonResponse(_fixture('watch_next.json'));
          }
          expect(body['continuation'], isNotEmpty);
          return _jsonResponse(_fixture('comments.json'));
        }),
      );

      final result = await youtube.videoCommentDataSource.getVideoComments(
        'dQw4w9WgXcQ',
      );

      expect(result, isA<Success<Page<VideoComment>, Exception>>());
      final page = (result as Success<Page<VideoComment>, Exception>).success;
      expect(nextRequestCount, 2);
      expect(page.number, 1);
      expect(page.data, isNotEmpty);
      expect(page.data.first.id, isNotEmpty);
      expect(page.data.first.authorName, isNotEmpty);
      expect(page.data.first.content, isNotEmpty);
      expect(page.data.where((comment) => comment.replyCount > 0), isNotEmpty);
      expect(page.totalPages, greaterThanOrEqualTo(1));

      await youtube.close();
    });

    test('returns an empty first page when comments are disabled', () async {
      final youtube = YouTube(
        httpClient: MockClient(
          (_) async => _jsonResponse('''
{
  "contents": {
    "twoColumnWatchNextResults": {
      "results": {
        "results": {
          "contents": [
            {
              "videoPrimaryInfoRenderer": {
                "title": {"runs": [{"text": "No comments here"}]}
              }
            }
          ]
        }
      }
    }
  }
}
'''),
        ),
      );

      final result = await youtube.videoCommentDataSource.getVideoComments(
        'dQw4w9WgXcQ',
      );

      expect(result, isA<Success<Page<VideoComment>, Exception>>());
      final page = (result as Success<Page<VideoComment>, Exception>).success;
      expect(page.data, isEmpty);
      expect(page.totalPages, 1);

      await youtube.close();
    });

    test('returns an error when the endpoint rejects the request', () async {
      final youtube = YouTube(
        httpClient: MockClient(
          (_) async => _jsonResponse('unavailable', statusCode: 503),
        ),
      );

      final result = await youtube.videoCommentDataSource.getVideoComments(
        'dQw4w9WgXcQ',
      );

      expect(result, isA<Error<Page<VideoComment>, Exception>>());
      await youtube.close();
    });
  });

  group('YouTubeMediaStreamRemoteDataSource', () {
    test('resolves adaptive video and audio formats from the player', () async {
      final youtube = YouTube(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/youtubei/v1/player');
          return _jsonResponse(_fixture('player.json'));
        }),
      );

      final result = await youtube.mediaStreamDataSource.getMediaStream(
        'dQw4w9WgXcQ',
      );

      expect(result, isA<Success<MediaStream, Exception>>());
      final stream = (result as Success<MediaStream, Exception>).success;
      expect(stream.videoUrl, startsWith('https://'));
      expect(stream.audioUrl, startsWith('https://'));
      expect(stream.headers['User-Agent'], isNotEmpty);
      expect(stream.height, 1080);
      expect(stream.qualityLabel, '1080p');
      expect(stream.streamId, isNotNull);
      expect(stream.codecs, isNotEmpty);
      expect(stream.alternatives, isNotEmpty);
      expect(
        stream.alternatives.map((option) => option.height),
        containsAll([2160, 1440, 720]),
      );

      await youtube.close();
    });

    test('honours the preferred height and stream id', () async {
      final youtube = YouTube(
        httpClient: MockClient(
          (_) async => _jsonResponse(_fixture('player.json')),
        ),
      );

      final byHeight = await youtube.mediaStreamDataSource.getMediaStream(
        'dQw4w9WgXcQ',
        preferHeight: 720,
      );
      expect(byHeight, isA<Success<MediaStream, Exception>>());
      expect((byHeight as Success<MediaStream, Exception>).success.height, 720);

      final byStreamId = await youtube.mediaStreamDataSource.getMediaStream(
        'dQw4w9WgXcQ',
        preferStreamId: 137,
      );
      expect(byStreamId, isA<Success<MediaStream, Exception>>());
      final selected = (byStreamId as Success<MediaStream, Exception>).success;
      expect(selected.streamId, 137);
      expect(selected.height, 1080);

      await youtube.close();
    });

    test('returns an error when the player request fails', () async {
      final youtube = YouTube(
        httpClient: MockClient(
          (_) async => _jsonResponse('unavailable', statusCode: 503),
        ),
      );

      final result = await youtube.mediaStreamDataSource.getMediaStream(
        'dQw4w9WgXcQ',
      );

      expect(result, isA<Error<MediaStream, Exception>>());
      await youtube.close();
    });
  });

  group('YouTubeUserVideosRemoteDataSource', () {
    test('maps the channel video tab into playable videos', () async {
      final youtube = YouTube(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/youtubei/v1/browse');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['browseId'], 'UCuAXFkgsw1L7xaCfnd5JJOw');
          expect(body['params'], isNotEmpty);
          return _jsonResponse(_fixture('browse.json'));
        }),
      );

      final result = await youtube.userVideosDataSource.fetchUserVideos(
        channelId: 'UCuAXFkgsw1L7xaCfnd5JJOw',
      );

      expect(result, isA<Success<Page<VideoModel>, Exception>>());
      final page = (result as Success<Page<VideoModel>, Exception>).success;
      expect(page.data, isNotEmpty);
      expect(page.data.every((video) => !video.id.startsWith('PXC_')), isTrue);
      expect(page.data.every((video) => video.title.isNotEmpty), isTrue);
      expect(page.data.first.url, contains('watch?v='));
      expect(page.data.first.viewCount, isNotNull);
      expect(page.data.first.uploadDate, isNotNull);

      await youtube.close();
    });

    test('returns an error when the channel request fails', () async {
      final youtube = YouTube(
        httpClient: MockClient(
          (_) async => _jsonResponse('unavailable', statusCode: 503),
        ),
      );

      final result = await youtube.userVideosDataSource.fetchUserVideos(
        channelId: 'UCuAXFkgsw1L7xaCfnd5JJOw',
      );

      expect(result, isA<Error<Page<VideoModel>, Exception>>());
      await youtube.close();
    });
  });

  group('YouTubePlaylistContentRemoteDataSource', () {
    test('maps a playlist page into a PlaylistDetail', () async {
      final youtube = YouTube(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/youtubei/v1/browse');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['browseId'], 'VLPL4cUxeGkcC9jLYyp2Aoh6hcWuxFDX6PBJ');
          return _jsonResponse(_fixture('browse_playlist.json'));
        }),
      );

      final result = await youtube.playlistContentDataSource
          .fetchPlaylistContent(
            playlistId: 'PL4cUxeGkcC9jLYyp2Aoh6hcWuxFDX6PBJ',
          );

      expect(result, isA<Success<Page<PlaylistDetail>, Exception>>());
      final page = (result as Success<Page<PlaylistDetail>, Exception>).success;
      expect(page.data, hasLength(1));
      final detail = page.data.first;
      expect(detail.title, 'Flutter Tutorial for Beginners');
      expect(detail.totalCount, 36);
      expect(detail.creatorName, 'Net Ninja');
      expect(detail.items, isNotEmpty);
      expect(detail.items.first.id, isNotEmpty);
      expect(detail.items.first.duration, isNotNull);

      await youtube.close();
    });

    test('returns an error when the playlist request fails', () async {
      final youtube = YouTube(
        httpClient: MockClient(
          (_) async => _jsonResponse('unavailable', statusCode: 503),
        ),
      );

      final result = await youtube.playlistContentDataSource
          .fetchPlaylistContent(
            playlistId: 'PL4cUxeGkcC9jLYyp2Aoh6hcWuxFDX6PBJ',
          );

      expect(result, isA<Error<Page<PlaylistDetail>, Exception>>());
      await youtube.close();
    });
  });

  group('YouTube facade', () {
    test(
      'exposes every implemented capability with the youtube source id',
      () async {
        final youtube = YouTube();

        expect(youtube.videoDetailDataSource.sourceId, 'youtube');
        expect(youtube.videoCommentDataSource.sourceId, 'youtube');
        expect(youtube.mediaStreamDataSource.sourceId, 'youtube');
        expect(youtube.userVideosDataSource.sourceId, 'youtube');
        expect(youtube.playlistContentDataSource.sourceId, 'youtube');
        expect(youtube.videoCommentRepliesDataSource, isNull);
        expect(youtube.videoFeedDataSources, isEmpty);

        await youtube.close();
      },
    );
  });
}

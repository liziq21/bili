import 'dart:convert';
import 'dart:io';

import 'package:bilibili/bilibili.dart';
import 'package:bpi/bpi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

final class const MockNetworkBiliFeedDataSource(
  final NetworkBiliPopularResponse response, {
  final NetworkBiliRankingResponse? rankingResponse,
}) implements NetworkBiliFeedDataSource {
  @override
  Future<NetworkBiliPopularResponse> getPopular({
    int page = 1,
    int pageSize = 20,
  }) async => response;

  @override
  Future<NetworkBiliRankingResponse> getRanking({
    int rankingId = 0,
    String type = 'all',
  }) async => rankingResponse ?? (throw StateError('ranking not configured'));
}

final class const ThrowingNetworkBiliFeedDataSource()
    implements NetworkBiliFeedDataSource {
  @override
  Future<NetworkBiliPopularResponse> getPopular({
    int page = 1,
    int pageSize = 20,
  }) {
    throw const BpiHttpException('popular unavailable', statusCode: 503);
  }

  @override
  Future<NetworkBiliRankingResponse> getRanking({
    int rankingId = 0,
    String type = 'all',
  }) {
    throw const BpiHttpException('ranking unavailable', statusCode: 503);
  }
}

void main() {
  NetworkBiliPopularResponse loadPopularResponse() {
    final file = File('bpi/testing/popular.json');
    expect(file.existsSync(), isTrue);
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return NetworkBiliPopularResponse.fromJson(json);
  }

  NetworkBiliRankingResponse loadRankingResponse() {
    final file = File('bpi/testing/ranking.json');
    expect(file.existsSync(), isTrue);
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return NetworkBiliRankingResponse.fromJson(json);
  }

  test('maps popular DTOs to video models and pages', () async {
    final response = loadPopularResponse();
    final source = BiliPopularVideoFeedRemoteDataSource(
      network: MockNetworkBiliFeedDataSource(response),
    );

    final result = await source.fetchFeed();

    expect(result.isOk, isTrue);
    final page = switch (result) {
      Ok(:final value) => value,
      Error() => fail('expected a successful page'),
    };
    expect(page.number, 1);
    expect(page.totalPages, 2);
    expect(page.data, hasLength(20));

    final video = page.data.first;
    expect(video.id, 'BV1Deht6rEpZ');
    expect(video.title, isNotEmpty);
    expect(video.url, 'https://www.bilibili.com/video/BV1Deht6rEpZ');
    expect(video.thumbnailUrl, startsWith('https://'));
    expect(video.viewCount, greaterThan(0));
    expect(video.uploadDate, isNotNull);
    expect(video.creatorProfileName, isNotEmpty);
    expect(video.creatorProfileId, isNotEmpty);
  });

  test('maps ranking DTOs to a single video page', () async {
    final source = BiliRankingVideoFeedRemoteDataSource(
      network: MockNetworkBiliFeedDataSource(
        loadPopularResponse(),
        rankingResponse: loadRankingResponse(),
      ),
    );

    final result = await source.fetchFeed();

    expect(result.isOk, isTrue);
    final page = switch (result) {
      Ok(:final value) => value,
      Error() => fail('expected a successful page'),
    };
    expect(page.number, 1);
    expect(page.totalPages, 1);
    expect(page.data, hasLength(100));

    final video = page.data.first;
    expect(video.id, 'BV1YDhJ6ZEL6');
    expect(video.title, isNotEmpty);
    expect(video.url, 'https://www.bilibili.com/video/BV1YDhJ6ZEL6');
    expect(video.thumbnailUrl, startsWith('https://'));
    expect(video.viewCount, greaterThan(0));
    expect(video.uploadDate, isNotNull);
    expect(video.creatorProfileName, isNotEmpty);
    expect(video.creatorProfileId, isNotEmpty);
  });

  test(
    'marks the current page as the last page when no_more is true',
    () async {
      final response = NetworkBiliPopularResponse.fromJson({
        'code': 0,
        'message': 'OK',
        'ttl': 1,
        'data': {
          'no_more': true,
          'list': [
            {
              'aid': 1,
              'bvid': 'BVlast',
              'title': 'last',
              'pic': 'http://example.com/cover.jpg',
            },
          ],
        },
      });
      final source = BiliPopularVideoFeedRemoteDataSource(
        network: MockNetworkBiliFeedDataSource(response),
      );

      final result = await source.fetchFeed(pageKey: 3);

      expect(result.isOk, isTrue);
      final page = switch (result) {
        Ok(:final value) => value,
        Error() => fail('expected a successful page'),
      };
      expect(page.number, 3);
      expect(page.totalPages, 3);
    },
  );

  test('converts network failures to Result.error', () async {
    final source = BiliPopularVideoFeedRemoteDataSource(
      network: const ThrowingNetworkBiliFeedDataSource(),
    );

    final result = await source.fetchFeed();

    expect(result.isError, isTrue);
  });

  test('converts ranking network failures to Result.error', () async {
    final source = BiliRankingVideoFeedRemoteDataSource(
      network: const ThrowingNetworkBiliFeedDataSource(),
    );

    final result = await source.fetchFeed();

    expect(result.isError, isTrue);
  });

  test('registers popular and ranking video feeds', () async {
    final bili = Bili();
    addTearDown(bili.close);

    final feeds = bili.videoFeedDataSources;

    expect(feeds, hasLength(2));
    expect(feeds.map((feed) => feed.id), ['popular', 'ranking']);
    expect(feeds.map((feed) => feed.title), ['热门视频', '排行榜']);
    expect(feeds.every((feed) => feed.sourceId == 'bilibili'), isTrue);
  });
}

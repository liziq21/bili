import 'dart:convert';
import 'dart:io';

import 'package:bilibili/bilibili.dart';
import 'package:bpi/bpi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

final class _FakeNetworkUserDataSource({
  final NetworkBiliUserArticlesData? response,
  final Object? error,
}) implements NetworkUserDataSource {
  @override
  Future<NetworkBiliSeriesArchives> getSeriesArchives({
    required int mid,
    required int seriesId,
    int page = 1,
    int pageSize = 30,
  }) => throw UnimplementedError();

  int requestCount = 0;
  int? requestedMid;
  int? requestedPage;
  int? requestedPageSize;

  @override
  Future<NetworkBiliUserCardData> getUserCard({required int mid}) =>
      throw UnimplementedError();

  @override
  Future<NetworkBiliUserArticlesData> getUserArticles({
    required int mid,
    int page = 1,
    int pageSize = 30,
  }) async {
    requestCount++;
    requestedMid = mid;
    requestedPage = page;
    requestedPageSize = pageSize;
    if (error != null) throw error!;
    return response!;
  }

  @override
  Future<NetworkBiliPlaylistContentData> getPlaylistContent({
    required int mid,
    int pageNum = 1,
    int pageSize = 30,
    bool sortReverse = false,
    int? seasonId,
  }) => throw UnimplementedError();

  @override
  Future<NetworkBiliUserVideosData> getUserVideos({
    required int mid,
    int page = 1,
    int pageSize = 30,
    String? order,
  }) => throw UnimplementedError();
}

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('bpi/testing/user_articles.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test(
    'maps the real user article fixture to a paged article result',
    () async {
      final response = NetworkBiliUserArticlesData.fromJson(
        (loadFixture()['data'] as Map<String, dynamic>),
      );
      final network = _FakeNetworkUserDataSource(response: response);
      final source = BiliUserArticlesRemoteDataSource(network: network);

      final result = await source.fetchUserArticles(
        channelId: ' 353840826 ',
        page: 2,
        pageSize: 30,
      );

      expect(result.isSuccess(), isTrue);
      final page = switch (result) {
        Success(:final success) => success,
        Error() => fail('expected a successful page'),
      };
      expect(page.number, 2);
      expect(page.totalPages, 11);
      expect(page.data, hasLength(30));
      final first = page.data.first;
      expect(first.id, 'cv53109096');
      expect(first.title, '剧情活动预告');
      expect(first.url, 'https://www.bilibili.com/read/cv53109096');
      expect(first.thumbnailUrl, startsWith('https://'));
      expect(
        first.publishedAt,
        DateTime.fromMillisecondsSinceEpoch(1790050500 * 1000),
      );
      expect(network.requestCount, 1);
      expect(network.requestedMid, 353840826);
      expect(network.requestedPage, 2);
      expect(network.requestedPageSize, 30);
    },
  );

  test('falls back to the cv id when an article has no title', () async {
    final response = NetworkBiliUserArticlesData.fromJson({
      'articles': [
        {'id': 42},
      ],
      'count': 1,
    });
    final source = BiliUserArticlesRemoteDataSource(
      network: _FakeNetworkUserDataSource(response: response),
    );

    final result = await source.fetchUserArticles(channelId: '2');

    final page = switch (result) {
      Success(:final success) => success,
      Error() => fail('expected a successful page'),
    };
    expect(page.totalPages, 1);
    expect(page.data.single.id, 'cv42');
    expect(page.data.single.title, 'cv42');
    expect(page.data.single.url, 'https://www.bilibili.com/read/cv42');
  });

  test(
    'returns an error without making a request for an invalid channel',
    () async {
      final network = _FakeNetworkUserDataSource(
        response: NetworkBiliUserArticlesData.fromJson({}),
      );
      final source = BiliUserArticlesRemoteDataSource(network: network);

      final result = await source.fetchUserArticles(channelId: 'not-a-mid');

      expect(result.isError(), isTrue);
      expect(network.requestCount, 0);
    },
  );

  test('returns an error for non-positive pagination values', () async {
    final network = _FakeNetworkUserDataSource(
      response: NetworkBiliUserArticlesData.fromJson({}),
    );
    final source = BiliUserArticlesRemoteDataSource(network: network);

    expect(
      (await source.fetchUserArticles(channelId: '2', page: 0)).isError(),
      isTrue,
    );
    expect(
      (await source.fetchUserArticles(channelId: '2', pageSize: 0)).isError(),
      isTrue,
    );
    expect(network.requestCount, 0);
  });

  test('returns an error when the network call fails', () async {
    final network = _FakeNetworkUserDataSource(error: Exception('boom'));
    final source = BiliUserArticlesRemoteDataSource(network: network);

    final result = await source.fetchUserArticles(channelId: '2');

    expect(result.isError(), isTrue);
  });

  test(
    'registers the user article capability without prior source access',
    () async {
      final bili = Bili();
      addTearDown(bili.close);

      expect(
        bili.userArticlesDataSource,
        isA<BiliUserArticlesRemoteDataSource>(),
      );
    },
  );
}

import 'dart:convert';
import 'dart:io';

import 'package:bilibili/bilibili.dart';
import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

final class const _FakeBiliFeedDataSource({
  required final NetworkBiliPopularResponse popular,
  required final NetworkBiliRankingResponse ranking,
}) implements NetworkBiliFeedDataSource {
  @override
  Future<NetworkBiliPopularResponse> getPopular({
    int page = 1,
    int pageSize = 20,
  }) async => popular;

  @override
  Future<NetworkBiliRankingResponse> getRanking({
    int rankingId = 0,
    String type = 'all',
  }) async => ranking;
}

void main() {
  Map<String, dynamic> loadJson(String path) {
    final file = File(path);
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('declarative popular feed matches the typed adapter', () async {
    final json = loadJson('bpi/testing/popular.json');
    final declarative = createBiliPopularDeclarativeFeed(
      fetchJson: ({int? pageKey}) async => json,
    );
    final legacy = BiliPopularVideoFeedRemoteDataSource(
      network: _FakeBiliFeedDataSource(
        popular: NetworkBiliPopularResponse.fromJson(json),
        ranking: NetworkBiliRankingResponse.fromJson(
          loadJson('bpi/testing/ranking.json'),
        ),
      ),
    );

    final declarativePage = await _pageOf(declarative.fetchFeed());
    final legacyPage = await _pageOf(legacy.fetchFeed());

    expect(declarativePage.number, legacyPage.number);
    expect(declarativePage.totalPages, legacyPage.totalPages);
    expect(declarativePage.data, hasLength(legacyPage.data.length));
    for (var i = 0; i < legacyPage.data.length; i++) {
      _expectSameVideo(declarativePage.data[i], legacyPage.data[i]);
    }
  });

  test('declarative ranking feed matches the typed adapter', () async {
    final json = loadJson('bpi/testing/ranking.json');
    final declarative = createBiliRankingDeclarativeFeed(
      fetchJson: ({int? pageKey}) async => json,
    );
    final legacy = BiliRankingVideoFeedRemoteDataSource(
      network: _FakeBiliFeedDataSource(
        popular: NetworkBiliPopularResponse.fromJson(
          loadJson('bpi/testing/popular.json'),
        ),
        ranking: NetworkBiliRankingResponse.fromJson(json),
      ),
    );

    final declarativePage = await _pageOf(declarative.fetchFeed());
    final legacyPage = await _pageOf(legacy.fetchFeed());

    expect(declarativePage.number, 1);
    expect(declarativePage.totalPages, 1);
    expect(declarativePage.data, hasLength(legacyPage.data.length));
    for (var i = 0; i < legacyPage.data.length; i++) {
      _expectSameVideo(declarativePage.data[i], legacyPage.data[i]);
    }
  });

  test('returns Result.error on a failed envelope', () async {
    final result = await createBiliPopularDeclarativeFeed(
      fetchJson: ({int? pageKey}) async => {
        'code': -1,
        'message': 'boom',
        'data': {'no_more': true, 'list': <Object?>[]},
      },
    ).fetchFeed();

    expect(result.isError(), isTrue);
    final error = switch (result) {
      Error(:final error) => error,
      Success() => fail('expected an error'),
    };
    expect(error.toString(), contains('boom'));
  });

  test('marks the current page as last when no_more is true', () async {
    final result = await createBiliPopularDeclarativeFeed(
      fetchJson: ({int? pageKey}) async => {
        'code': 0,
        'message': 'OK',
        'data': {
          'no_more': true,
          'list': [
            {
              'bvid': 'BVlast',
              'title': 'last',
              'pic': 'http://example.com/cover.jpg',
            },
          ],
        },
      },
    ).fetchFeed(pageKey: 3);

    final page = switch (result) {
      Success(:final success) => success,
      Error(:final error) => fail('expected success: $error'),
    };
    expect(page.number, 3);
    expect(page.totalPages, 3);
    expect(page.data.single.id, 'BVlast');
  });

  test('drops items without a bvid', () async {
    final result = await createBiliPopularDeclarativeFeed(
      fetchJson: ({int? pageKey}) async => {
        'code': 0,
        'message': 'OK',
        'data': {
          'no_more': true,
          'list': [
            {'bvid': 'BVok', 'title': 'ok'},
            {'title': 'missing id'},
          ],
        },
      },
    ).fetchFeed();

    final page = switch (result) {
      Success(:final success) => success,
      Error(:final error) => fail('expected success: $error'),
    };
    expect(page.data.map((video) => video.id), ['BVok']);
  });
}

Future<Page<VideoModel>> _pageOf(
  Future<Result<Page<VideoModel>, Exception>> future,
) async {
  final result = await future;
  return switch (result) {
    Success(:final success) => success,
    Error(:final error) => fail('expected success: $error'),
  };
}

void _expectSameVideo(VideoModel actual, VideoModel expected) {
  expect(actual.id, expected.id);
  expect(actual.title, expected.title);
  expect(actual.url, expected.url);
  expect(actual.thumbnailUrl, expected.thumbnailUrl);
  expect(actual.viewCount, expected.viewCount);
  expect(actual.uploadDate, expected.uploadDate);
  expect(actual.duration, expected.duration);
  expect(actual.creatorProfileName, expected.creatorProfileName);
  expect(actual.creatorProfileId, expected.creatorProfileId);
}

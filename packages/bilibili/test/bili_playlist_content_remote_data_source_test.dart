import 'dart:convert';
import 'dart:io';

import 'package:bilibili/bilibili.dart';
import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

final class _FakeNetworkUserDataSource({
  final NetworkBiliPlaylistContentData? response,
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
  int? requestedPageNum;
  int? requestedPageSize;
  int? requestedSeasonId;

  @override
  Future<NetworkBiliUserCardData> getUserCard({required int mid}) =>
      throw UnimplementedError();

  @override
  Future<NetworkBiliUserArticlesData> getUserArticles({
    required int mid,
    int page = 1,
    int pageSize = 30,
  }) => throw UnimplementedError();

  @override
  Future<NetworkBiliPlaylistContentData> getPlaylistContent({
    required int mid,
    int pageNum = 1,
    int pageSize = 30,
    bool sortReverse = false,
    int? seasonId,
  }) async {
    requestCount++;
    requestedMid = mid;
    requestedPageNum = pageNum;
    requestedPageSize = pageSize;
    requestedSeasonId = seasonId;
    if (error != null) throw error!;
    return response!;
  }

  @override
  Future<NetworkBiliUserVideosData> getUserVideos({
    required int mid,
    int page = 1,
    int pageSize = 30,
    String? order,
  }) => throw UnimplementedError();
}

void main() {
  NetworkBiliPlaylistContentData loadFixture() {
    final file = File('bpi/testing/playlist_content.json');
    expect(file.existsSync(), isTrue);
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return NetworkBiliPlaylistContentData.fromJson(
      json['data'] as Map<String, dynamic>,
    );
  }

  group('BiliPlaylistContentRemoteDataSource', () {
    test(
      'maps the real seasons_archives_list fixture to a detail page',
      () async {
        final network = _FakeNetworkUserDataSource(response: loadFixture());
        final source = BiliPlaylistContentRemoteDataSource(network: network);

        final result = await source.fetchPlaylistContent(
          playlistId: '946974:2046621',
          page: 1,
          pageSize: 30,
        );

        expect(result.isSuccess(), isTrue);
        final page = switch (result) {
          Success(:final success) => success,
          Error() => fail('expected a successful page'),
        };
        expect(page.number, 1);
        expect(page.totalPages, 1);
        expect(page.data, hasLength(1));
        final detail = page.data.single;
        expect(detail.id, '946974:2046621');
        expect(detail.title, '合集·样片日记');
        expect(detail.description, isEmpty);
        expect(detail.coverUrl, startsWith('https://'));
        expect(detail.creatorId, '946974');
        expect(detail.totalCount, 26);
        expect(detail.items, hasLength(5));
        final video = detail.items.first;
        expect(video.id, 'BV1be41127ft');
        expect(video.title, '零下26度的新疆，跟着影视飓风去拍样片！');
        expect(video.thumbnailUrl, startsWith('https://'));
        // 详情端点把播放量放在 stat.view、时长放在秒数字段，而不是 play/length。
        expect(video.viewCount, 3303255);
        expect(video.duration, 974);
        expect(network.requestedMid, 946974);
        expect(network.requestedSeasonId, 2046621);
        expect(network.requestedPageNum, 1);
        expect(network.requestedPageSize, 30);
      },
    );

    test('computes total pages from the advertised playlist total', () async {
      final network = _FakeNetworkUserDataSource(response: loadFixture());
      final source = BiliPlaylistContentRemoteDataSource(network: network);

      final result = await source.fetchPlaylistContent(
        playlistId: '946974:2046621',
        pageSize: 5,
      );

      final page = switch (result) {
        Success(:final success) => success,
        Error() => fail('expected a successful page'),
      };
      expect(page.totalPages, 6);
    });

    test('falls back to the items_lists series shape', () async {
      final data = NetworkBiliPlaylistContentData.fromJson({
        'items_lists': {
          'page': {'page_num': 1, 'page_size': 30, 'total': 1},
          'seasons_list': <Object>[],
          'series_list': [
            {
              'series_id': 12345,
              'archives': [
                {
                  'aid': 1,
                  'bvid': 'BV1xx411x7vy',
                  'title': 'Series Video',
                  'play': 10000,
                  'length': '03:25',
                },
              ],
              'meta': {
                'series_id': 12345,
                'name': 'Test Series',
                'description': 'Series description',
                'creator': 'author',
                'mid': 2,
                'total': 1,
                'cover': 'https://i0.hdslb.com/cover.jpg',
              },
            },
          ],
        },
      });
      final network = _FakeNetworkUserDataSource(response: data);
      final source = BiliPlaylistContentRemoteDataSource(network: network);

      final result = await source.fetchPlaylistContent(playlistId: '2:12345');

      final page = switch (result) {
        Success(:final success) => success,
        Error() => fail('expected a successful page'),
      };
      final detail = page.data.single;
      expect(detail.title, 'Test Series');
      expect(detail.description, 'Series description');
      expect(detail.creatorName, 'author');
      expect(detail.items.single.id, 'BV1xx411x7vy');
    });

    test('skips archives missing a core id instead of failing', () async {
      final data = NetworkBiliPlaylistContentData.fromJson({
        'archives': [
          {
            'aid': 1,
            'bvid': 'BV1valid',
            'title': 'Valid',
            'duration': 60,
            'stat': {'view': 5},
          },
          {'aid': 2, 'title': 'Missing bvid'},
          {'bvid': 'BV1missingAid', 'title': 'Missing aid'},
        ],
        'meta': {'season_id': 777, 'name': 'Mixed', 'mid': 2, 'total': 3},
        'page': {'page_num': 1, 'page_size': 30, 'total': 3},
      });
      final network = _FakeNetworkUserDataSource(response: data);
      final source = BiliPlaylistContentRemoteDataSource(network: network);

      final result = await source.fetchPlaylistContent(playlistId: '2:777');

      final page = switch (result) {
        Success(:final success) => success,
        Error() => fail('expected a successful page'),
      };
      final detail = page.data.single;
      expect(detail.items, hasLength(1));
      expect(detail.items.single.id, 'BV1valid');
    });

    test('uses the page total when metadata omits a total', () async {
      final data = NetworkBiliPlaylistContentData.fromJson({
        'archives': [
          {'aid': 1, 'bvid': 'BV1valid', 'title': 'Only'},
        ],
        'meta': {'season_id': 777, 'name': 'No total', 'mid': 2},
        'page': {'page_num': 1, 'page_size': 30, 'total': 42},
      });
      final network = _FakeNetworkUserDataSource(response: data);
      final source = BiliPlaylistContentRemoteDataSource(network: network);

      final result = await source.fetchPlaylistContent(
        playlistId: '2:777',
        pageSize: 30,
      );

      final page = switch (result) {
        Success(:final success) => success,
        Error() => fail('expected a successful page'),
      };
      final detail = page.data.single;
      expect(detail.totalCount, 42);
      expect(page.totalPages, 2);
    });

    test(
      'rejects a playlist id without an owner mid before any request',
      () async {
        final network = _FakeNetworkUserDataSource(response: loadFixture());
        final source = BiliPlaylistContentRemoteDataSource(network: network);

        final result = await source.fetchPlaylistContent(playlistId: '12345');

        expect(result.isError(), isTrue);
        expect(network.requestCount, 0);
      },
    );

    test('rejects malformed playlist ids before any request', () async {
      final network = _FakeNetworkUserDataSource(response: loadFixture());
      final source = BiliPlaylistContentRemoteDataSource(network: network);

      for (final id in ['', '  ', 'abc', '-1:5', '2:-5', '2:3:4', ':5']) {
        expect(
          (await source.fetchPlaylistContent(playlistId: id)).isError(),
          isTrue,
          reason: 'expected "$id" to be rejected',
        );
      }
      expect(network.requestCount, 0);
    });

    test('rejects non-positive pagination values', () async {
      final network = _FakeNetworkUserDataSource(response: loadFixture());
      final source = BiliPlaylistContentRemoteDataSource(network: network);

      expect(
        (await source.fetchPlaylistContent(
          playlistId: '2:12345',
          page: 0,
        )).isError(),
        isTrue,
      );
      expect(
        (await source.fetchPlaylistContent(
          playlistId: '2:12345',
          pageSize: 0,
        )).isError(),
        isTrue,
      );
      expect(network.requestCount, 0);
    });

    test('converts network failures to an error result', () async {
      final source = BiliPlaylistContentRemoteDataSource(
        network: _FakeNetworkUserDataSource(error: StateError('unavailable')),
      );

      final result = await source.fetchPlaylistContent(playlistId: '2:12345');

      expect(result.isError(), isTrue);
    });
  });

  group('NetworkBiliPlaylistRef', () {
    test('parses and formats owner scoped playlist ids', () {
      final ref = NetworkBiliPlaylistRef.parse(' 2 : 12345 ');

      expect(ref, isNotNull);
      expect(ref!.id, 12345);
      expect(ref.ownerId, 2);
      expect(
        NetworkBiliPlaylistRef.format(ownerId: '2', playlistId: '12345'),
        '2:12345',
      );
    });

    test('parses an id-only reference without an owner', () {
      final ref = NetworkBiliPlaylistRef.parse('12345');

      expect(ref, isNotNull);
      expect(ref!.id, 12345);
      expect(ref.ownerId, isNull);
    });
  });

  test('registers the playlist content capability', () async {
    final bili = Bili();
    addTearDown(bili.close);

    expect(
      bili.playlistContentDataSource,
      isA<PlaylistContentRemoteDataSource>(),
    );
  });
}

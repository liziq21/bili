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
    test('maps the real playlist fixture to a playlist detail page', () async {
      final network = _FakeNetworkUserDataSource(response: loadFixture());
      final source = BiliPlaylistContentRemoteDataSource(network: network);

      final result = await source.fetchPlaylistContent(
        playlistId: '2:12345',
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
      expect(detail.id, '2:12345');
      expect(detail.title, 'Test Playlist');
      expect(detail.description, 'Test playlist description');
      expect(detail.coverUrl, startsWith('https://'));
      expect(detail.creatorName, 'auto');
      expect(detail.creatorId, '2');
      expect(detail.totalCount, 1);
      expect(detail.items, hasLength(1));
      final video = detail.items.single;
      expect(video.id, 'BV1xx411x7vy');
      expect(video.title, 'Test Video Title');
      expect(video.thumbnailUrl, startsWith('https://'));
      expect(video.viewCount, 10000);
      expect(video.duration, 205);
      expect(video.creatorProfileName, 'Test Author');
      expect(video.creatorProfileId, '2');
      expect(network.requestedMid, 2);
      expect(network.requestedSeasonId, 12345);
      expect(network.requestedPageNum, 1);
      expect(network.requestedPageSize, 30);
    });

    test('computes total pages from the advertised playlist total', () async {
      final network = _FakeNetworkUserDataSource(response: loadFixture());
      final source = BiliPlaylistContentRemoteDataSource(network: network);

      final result = await source.fetchPlaylistContent(
        playlistId: '2:12345',
        pageSize: 1,
      );

      final page = switch (result) {
        Success(:final success) => success,
        Error() => fail('expected a successful page'),
      };
      expect(page.totalPages, 1);
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

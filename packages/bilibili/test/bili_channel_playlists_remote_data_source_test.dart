import 'dart:convert';
import 'dart:io';

import 'package:bilibili/bilibili.dart';
import 'package:bpi/bpi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

final class _FakeNetworkPlaylistDataSource({
  final NetworkBiliPlaylistListData? response,
  final Object? error,
}) implements NetworkUserPlaylistDataSource {
  int requestCount = 0;
  int? requestedMid;
  int? requestedPageNum;
  int? requestedPageSize;

  @override
  Future<NetworkBiliPlaylistListData> getUserPlaylists({
    required int mid,
    int pageNum = 1,
    int pageSize = 30,
  }) async {
    requestCount++;
    requestedMid = mid;
    requestedPageNum = pageNum;
    requestedPageSize = pageSize;
    if (error != null) throw error!;
    return response!;
  }
}

void main() {
  NetworkBiliPlaylistListData loadFixture() {
    final file = File('bpi/testing/playlist_list.json');
    expect(file.existsSync(), isTrue);
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return NetworkBiliPlaylistListData.fromJson(
      json['data'] as Map<String, dynamic>,
    );
  }

  group('BiliChannelPlaylistsRemoteDataSource', () {
    test(
      'maps the real seasons_series_list fixture to season headers',
      () async {
        final network = _FakeNetworkPlaylistDataSource(response: loadFixture());
        final source = BiliChannelPlaylistsRemoteDataSource(network: network);

        final result = await source.fetchChannelPlaylists(
          channelId: '517327498',
        );

        expect(result.isSuccess(), isTrue);
        final page = switch (result) {
          Success(:final success) => success,
          Error() => fail('expected a successful page'),
        };
        expect(page.number, 1);
        expect(page.totalPages, 1);
        expect(page.data, hasLength(2));
        final season = page.data.first;
        expect(season.id, '517327498:3993361');
        expect(season.title, '合集·经典领读');
        expect(season.totalCount, 22);
        expect(season.coverUrl, startsWith('https://'));
        expect(season.creatorId, '517327498');
        expect(season.items, isEmpty);
        expect(network.requestedMid, 517327498);
        expect(network.requestedPageNum, 1);
        expect(network.requestedPageSize, 30);
      },
    );

    test(
      'computes total pages from the combined season and series total',
      () async {
        final network = _FakeNetworkPlaylistDataSource(response: loadFixture());
        final source = BiliChannelPlaylistsRemoteDataSource(network: network);

        final result = await source.fetchChannelPlaylists(
          channelId: '517327498',
          pageSize: 2,
        );

        final page = switch (result) {
          Success(:final success) => success,
          Error() => fail('expected a successful page'),
        };
        expect(page.totalPages, 3);
      },
    );

    test('rejects a non-numeric channel id without a request', () async {
      final network = _FakeNetworkPlaylistDataSource(response: loadFixture());
      final source = BiliChannelPlaylistsRemoteDataSource(network: network);

      final result = await source.fetchChannelPlaylists(channelId: 'UC123');

      expect(result.isError(), isTrue);
      expect(network.requestCount, 0);
    });

    test('maps a network failure to an error result', () async {
      final network = _FakeNetworkPlaylistDataSource(
        error: Exception('network down'),
      );
      final source = BiliChannelPlaylistsRemoteDataSource(network: network);

      final result = await source.fetchChannelPlaylists(channelId: '517327498');

      expect(result.isError(), isTrue);
    });
  });
}

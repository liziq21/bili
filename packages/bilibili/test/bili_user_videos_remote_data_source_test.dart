import 'dart:convert';
import 'dart:io';

import 'package:bilibili/bilibili.dart';
import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

final class _FakeNetworkUserDataSource({
  final NetworkBiliUserVideosData? response,
  final Object? error,
}) implements NetworkUserDataSource {
  int requestCount = 0;
  int? requestedMid;
  int? requestedPage;
  int? requestedPageSize;
  String? requestedOrder;

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
  }) => throw UnimplementedError();

  @override
  Future<NetworkBiliUserVideosData> getUserVideos({
    required int mid,
    int page = 1,
    int pageSize = 30,
    String? order,
  }) async {
    requestCount++;
    requestedMid = mid;
    requestedPage = page;
    requestedPageSize = pageSize;
    requestedOrder = order;
    if (error != null) throw error!;
    return response!;
  }
}

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('bpi/testing/space_videos.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('maps the real user video fixture to a paged video result', () async {
    final response = NetworkBiliUserVideosData.fromJson(
      (loadFixture()['data'] as Map<String, dynamic>),
    );
    final network = _FakeNetworkUserDataSource(response: response);
    final source = BiliUserVideosRemoteDataSource(network: network);

    final result = await source.fetchUserVideos(
      channelId: ' 2 ',
      page: 2,
      pageSize: 30,
    );

    expect(result.isSuccess(), isTrue);
    final page = switch (result) {
      Success(:final success) => success,
      Error() => fail('expected a successful page'),
    };
    expect(page.number, 2);
    expect(page.totalPages, 2);
    expect(page.data, hasLength(30));
    expect(page.data.first.id, 'BV1ujNV6qEXg');
    expect(page.data.first.title, '帮不帮？');
    expect(page.data.first.thumbnailUrl, startsWith('https://'));
    expect(page.data.first.viewCount, 759866);
    expect(page.data.first.duration, 22);
    expect(page.data.first.creatorProfileName, '碧诗');
    expect(page.data.first.creatorProfileId, '2');
    expect(network.requestCount, 1);
    expect(network.requestedMid, 2);
    expect(network.requestedPage, 2);
    expect(network.requestedPageSize, 30);
    expect(network.requestedOrder, 'pubdate');
  });

  test(
    'returns an error without making a request for an invalid channel',
    () async {
      final network = _FakeNetworkUserDataSource(
        response: NetworkBiliUserVideosData.fromJson({}),
      );
      final source = BiliUserVideosRemoteDataSource(network: network);

      final result = await source.fetchUserVideos(channelId: 'not-a-mid');

      expect(result.isError(), isTrue);
      expect(network.requestCount, 0);
    },
  );

  test('returns an error for non-positive pagination values', () async {
    final network = _FakeNetworkUserDataSource(
      response: NetworkBiliUserVideosData.fromJson({}),
    );
    final source = BiliUserVideosRemoteDataSource(network: network);

    expect(
      (await source.fetchUserVideos(channelId: '2', page: 0)).isError(),
      isTrue,
    );
    expect(
      (await source.fetchUserVideos(channelId: '2', pageSize: 0)).isError(),
      isTrue,
    );
    expect(network.requestCount, 0);
  });

  test('converts network failures to an error result', () async {
    final source = BiliUserVideosRemoteDataSource(
      network: _FakeNetworkUserDataSource(error: StateError('unavailable')),
    );

    final result = await source.fetchUserVideos(channelId: '2');

    expect(result.isError(), isTrue);
  });

  test(
    'registers the user video capability without prior source access',
    () async {
      final bili = Bili();
      addTearDown(bili.close);

      expect(bili.userVideosDataSource, isA<UserVideosRemoteDataSource>());
    },
  );
}

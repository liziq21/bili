import 'dart:convert';
import 'dart:io';

import 'package:bilibili/bilibili.dart';
import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

final class const FakeNetworkLiveDataSource({
  required final NetworkLiveRecommendedRooms response,
  final Exception? error,
}) implements NetworkLiveDataSource {
  @override
  Future<NetworkLiveRecommendedRooms> getRecommendedLiveRooms({
    int pageSize = 30,
  }) async {
    final failure = error;
    if (failure != null) throw failure;
    return response;
  }

  @override
  Future<NetworkLiveRoomDetail> getLiveRoomDetail({required int roomId}) =>
      throw UnimplementedError();

  @override
  Future<NetworkLiveRoomBaseInfo> getLiveRoomBaseInfo({
    required List<int> roomIds,
  }) => throw UnimplementedError();

  @override
  Future<NetworkLiveStatusByUids> getLiveStatusByUids({
    required List<int> uids,
  }) => throw UnimplementedError();

  @override
  Future<NetworkLiveRoomPlayInfo> getLiveRoomPlayInfo({
    required int roomId,
    int qn = 10000,
    String protocol = '0,1',
    String format = '0,1,2',
    String codec = '0,1',
    String platform = 'web',
    int ptype = 8,
  }) => throw UnimplementedError();

  @override
  Future<NetworkLiveDanmakuInfo> getDanmuInfo({required int roomId}) =>
      throw UnimplementedError();
}

void main() {
  NetworkLiveRecommendedRooms loadRecommendedRooms() {
    final file = File('bpi/testing/live_recommended_rooms.json');
    expect(file.existsSync(), isTrue);
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return NetworkLiveRecommendedRooms.fromJson(json);
  }

  test('maps recommended rooms to live models without searching', () async {
    final source = BiliRecommendLiveRoomFeedRemoteDataSource(
      network: FakeNetworkLiveDataSource(response: loadRecommendedRooms()),
    );

    final result = await source.fetchFeed();

    expect(result.isSuccess(), isTrue);
    final page = switch (result) {
      Success(:final success) => success,
      Error() => fail('expected a successful page'),
    };
    expect(page.number, 1);
    expect(page.totalPages, 1);
    expect(page.data, hasLength(30));

    final room = page.data.first;
    expect(room.id, 1883358196);
    expect(room.title, 'LVG vs Wildcard');
    expect(room.url, 'https://live.bilibili.com/1883358196');
    expect(room.isLive, isTrue);
    expect(room.thumbnailUrl, startsWith('https://'));
    expect(room.creatorProfileName, 'CS-advent');
    expect(room.creatorProfileId, '3546687211572101');
  });

  test('stops at the single recommended page', () async {
    final source = BiliRecommendLiveRoomFeedRemoteDataSource(
      network: FakeNetworkLiveDataSource(response: loadRecommendedRooms()),
    );

    final result = await source.fetchFeed(pageKey: 2);

    final page = switch (result) {
      Success(:final success) => success,
      Error() => fail('expected a successful page'),
    };
    expect(page.data, isEmpty);
  });

  test('projects a risk-control rejection onto RateLimitedFailure', () async {
    final source = BiliRecommendLiveRoomFeedRemoteDataSource(
      network: FakeNetworkLiveDataSource(
        response: loadRecommendedRooms(),
        error: const BiliRiskControlException('too many requests'),
      ),
    );

    final result = await source.fetchFeed();

    expect(result.tryGetError(), isA<RateLimitedFailure>());
  });
}

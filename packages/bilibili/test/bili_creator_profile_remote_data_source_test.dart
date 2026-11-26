import 'dart:convert';
import 'dart:io';

import 'package:bilibili/bilibili.dart';
import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

final class FakeNetworkUserDataSource({
  required final NetworkBiliUserCardData card,
  final Exception? error,
}) implements NetworkUserDataSource {
  final List<int> requestedMids = [];

  @override
  Future<NetworkBiliUserCardData> getUserCard({required int mid}) async {
    requestedMids.add(mid);
    final failure = error;
    if (failure != null) throw failure;
    return card;
  }

  @override
  Future<NetworkBiliSeriesArchives> getSeriesArchives({
    required int mid,
    required int seriesId,
    int page = 1,
    int pageSize = 30,
  }) => throw UnimplementedError();

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
  }) => throw UnimplementedError();
}

void main() {
  NetworkBiliUserCardData loadUserCard() {
    final file = File('bpi/testing/user_card.json');
    expect(file.existsSync(), isTrue);
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return NetworkBiliUserCardData.fromJson(
      json['data'] as Map<String, dynamic>,
    );
  }

  test('maps the user card to a creator profile', () async {
    final network = FakeNetworkUserDataSource(card: loadUserCard());
    final source = BiliCreatorProfileRemoteDataSource(network: network);

    final result = await source.getProfile('2');

    expect(result.isSuccess(), isTrue);
    final profile = switch (result) {
      Success(:final success) => success,
      Error() => fail('expected a successful profile'),
    };
    expect(network.requestedMids, [2]);
    expect(profile.id, '2');
    expect(profile.name, '碧诗');
    expect(profile.thumbnailUrl, startsWith('https://'));
    expect(profile.description, contains('kami.im'));
    expect(profile.subscribers, 1430413);
    expect(profile.videos, 8);
  });

  test('rejects a non-numeric id before any request', () async {
    final network = FakeNetworkUserDataSource(card: loadUserCard());
    final source = BiliCreatorProfileRemoteDataSource(network: network);

    final result = await source.getProfile('not-a-mid');

    expect(result.tryGetError(), isA<Exception>());
    expect(network.requestedMids, isEmpty);
  });

  test('projects a risk-control rejection onto RateLimitedFailure', () async {
    final source = BiliCreatorProfileRemoteDataSource(
      network: FakeNetworkUserDataSource(
        card: loadUserCard(),
        error: const BiliRiskControlException('too many requests'),
      ),
    );

    final result = await source.getProfile('2');

    expect(result.tryGetError(), isA<RateLimitedFailure>());
  });
}

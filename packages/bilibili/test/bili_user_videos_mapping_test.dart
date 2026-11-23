import 'dart:convert';
import 'dart:io';

import 'package:bilibili/bilibili.dart';
import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

final class _FakeNetworkUserDataSource({
  required final NetworkBiliUserVideosData response,
}) implements NetworkUserDataSource {
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
  }) async => response;
}

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('bpi/testing/space_videos.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('declarative user videos feed matches the typed adapter', () async {
    final fixture = loadFixture();
    final response = NetworkBiliUserVideosData.fromJson(
      fixture['data'] as Map<String, dynamic>,
    );
    final declarative = createBiliUserVideosDeclarativeFeed(
      fetchJson: ({int? pageKey}) async => fixture,
    );
    final legacy = BiliUserVideosRemoteDataSource(
      network: _FakeNetworkUserDataSource(response: response),
    );

    final declarativePage = await _pageOf(declarative.fetchFeed());
    final legacyPage = await _pageOf(
      legacy.fetchUserVideos(channelId: '2', page: 1, pageSize: 30),
    );

    expect(declarativePage.number, legacyPage.number);
    expect(declarativePage.totalPages, legacyPage.totalPages);
    expect(declarativePage.totalPages, 2);
    expect(declarativePage.data, hasLength(legacyPage.data.length));
    expect(declarativePage.data, hasLength(30));
    expect(
      declarativePage.data.map((video) => video.id).toSet(),
      hasLength(30),
    );
    for (var index = 0; index < legacyPage.data.length; index++) {
      _expectSameVideo(declarativePage.data[index], legacyPage.data[index]);
    }

    final first = declarativePage.data.first;
    expect(first.id, 'BV1ujNV6qEXg');
    expect(first.title, '帮不帮？');
    expect(first.url, 'https://www.bilibili.com/video/BV1ujNV6qEXg');
    expect(first.viewCount, 759866);
    expect(first.uploadDate?.millisecondsSinceEpoch, 1783878096000);
    expect(first.duration, 22);
    expect(first.creatorProfileName, '碧诗');
    expect(first.creatorProfileId, '2');
    expect(first.desc, contains('征兵场景'));
  });

  test('declarative user videos descriptor targets the canonical version', () {
    expect(biliUserVideosDescriptor.schemaVersion, VideoModel.schemaVersion);
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
  expect(actual.desc, expected.desc);
  expect(actual.creatorProfileName, expected.creatorProfileName);
  expect(actual.creatorProfileId, expected.creatorProfileId);
}

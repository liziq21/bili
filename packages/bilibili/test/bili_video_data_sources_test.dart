import 'dart:convert';
import 'dart:io';

import 'package:bilibili/bilibili.dart';
import 'package:bpi/bpi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

class MockNetworkVideoDataSource({
  required final Map<String, dynamic> videoDetailJson,
  required final Map<String, dynamic> videoRelationJson,
  required final List<dynamic> relatedVideosJson,
  required final Map<String, dynamic> replyListJson,
}) implements NetworkVideoDataSource {
  @override
  Future<VideoDetailData> getVideoDetail({required String bvid}) async {
    return VideoDetailData.fromJson(
      videoDetailJson['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<NetworkVideoRelation> getVideoRelation({required String bvid}) async {
    return NetworkVideoRelation.fromJson(
      videoRelationJson['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<NetworkRelatedVideo>> getRelatedVideos({
    required String bvid,
  }) async {
    return (relatedVideosJson)
        .map((e) => NetworkRelatedVideo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<NetworkReplyData> getReplyList({
    required int oid,
    required int type,
    int page = 1,
    int sort = 1,
    String? nextOffset,
  }) async {
    return NetworkReplyData.fromJson(
      replyListJson['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<NetworkReplyReplyData> getReplyReplyList({
    required int oid,
    required int root,
    required int type,
    int page = 1,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<NetworkPlayUrl> getPlayUrl({
    required String bvid,
    required int cid,
    int qn = 80,
    int fnval = 4048,
    int fourk = 1,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  File findFile(String fileName) {
    final candidatePaths = [
      'packages/bilibili/bpi/testing/$fileName',
      'bpi/testing/$fileName',
    ];
    for (final path in candidatePaths) {
      final file = File(path);
      if (file.existsSync()) return file;
    }
    return File(candidatePaths.first);
  }

  dynamic loadJson(String fileName) {
    final file = findFile(fileName);
    return jsonDecode(file.readAsStringSync());
  }

  group(
    'BiliVideoDetailRemoteDataSource & BiliVideoCommentRemoteDataSource',
    () {
      late MockNetworkVideoDataSource mockNetwork;
      late BiliVideoDetailRemoteDataSource detailDataSource;
      late BiliVideoCommentRemoteDataSource commentDataSource;

      setUp(() {
        final detailJson = loadJson('video_detail.json');
        final relationJson = loadJson('video_relation.json');
        final relatedJson = loadJson('related_videos.json');
        final replyJson = loadJson('reply_list.json');

        mockNetwork = MockNetworkVideoDataSource(
          videoDetailJson: detailJson as Map<String, dynamic>,
          videoRelationJson: relationJson as Map<String, dynamic>,
          relatedVideosJson:
              (relatedJson as Map<String, dynamic>)['data'] as List<dynamic>,
          replyListJson: replyJson as Map<String, dynamic>,
        );

        detailDataSource = BiliVideoDetailRemoteDataSource(
          network: mockNetwork,
        );
        commentDataSource = BiliVideoCommentRemoteDataSource(
          network: mockNetwork,
        );
      });

      test(
        'getVideoDetail maps detail, owner, relation, and related videos',
        () async {
          final result = await detailDataSource.getVideoDetail('BV1GJ411x7vy');
          expect(result.isOk, isTrue);

          final detail = (result as dynamic).value;
          expect(detail.video.id, equals('BV1GJ411x7vy'));
          expect(detail.video.title, isNotEmpty);
          expect(detail.creator, isNotNull);
          expect(detail.creator?.name, isNotEmpty);
          expect(detail.relatedVideos, isNotEmpty);
        },
      );

      test('getVideoComments maps reply list to VideoComment page', () async {
        final result = await commentDataSource.getVideoComments(
          'BV1GJ411x7vy',
          page: 1,
        );
        expect(result.isOk, isTrue);

        final page = (result as dynamic).value;
        expect(page.number, equals(1));
        expect(page.data, isNotEmpty);
        expect(page.data.first.authorName, isNotEmpty);
      });
    },
  );
}

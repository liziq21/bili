import 'dart:convert';
import 'dart:io';

import 'package:bilibili/bilibili.dart';
import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model/model.dart';

class MockNetworkVideoDataSource({
  required final Map<String, dynamic> videoDetailJson,
  required final Map<String, dynamic> videoRelationJson,
  required final List<dynamic> relatedVideosJson,
  required final Map<String, dynamic> replyListJson,
  required final Map<String, dynamic> replyReplyListJson,

  /// 章节来源（player/v2）的响应；为 null 时按原始响应构造。
  var Map<String, dynamic>? playerInfoJson,

  /// 让 player/v2 抛错，用来验证降级路径。
  var Object? playerInfoError,
  final NetworkBiliDanmakuDocument? danmakuDocument,
}) implements NetworkVideoDataSource {
  final replyReplyCalls = <(int, int, int, int)>[];

  final playerInfoCalls = <(String, int)>[];

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
    replyReplyCalls.add((oid, root, type, page));
    return NetworkReplyReplyData.fromJson(
      replyReplyListJson['data'] as Map<String, dynamic>,
    );
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

  @override
  Future<NetworkBiliPlayerInfo> getPlayerInfo({
    required String bvid,
    required int cid,
  }) async {
    playerInfoCalls.add((bvid, cid));
    final error = playerInfoError;
    if (error != null) throw error;
    // retrofit 层已经把响应体的 data 拆出来，模型直接对应 data。
    return NetworkBiliPlayerInfo.fromJson(
      playerInfoJson ?? const <String, dynamic>{'aid': 0, 'bvid': '', 'cid': 0},
    );
  }

  @override
  Future<NetworkBiliDanmakuDocument> getDanmaku({required int cid}) async {
    final document = danmakuDocument;
    if (document == null) throw UnimplementedError();
    return document;
  }

  @override
  Future<NetworkBangumiSeasonData> getBangumiSeason({
    int? seasonId,
    int? epId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<NetworkPlayUrl> getBangumiPlayUrl({
    int? epId,
    int? cid,
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

  group('BiliVideoDetailRemoteDataSource & BiliVideoCommentRemoteDataSource', () {
    late MockNetworkVideoDataSource mockNetwork;
    late BiliVideoDetailRemoteDataSource detailDataSource;
    late BiliVideoCommentRemoteDataSource commentDataSource;
    late BiliDanmakuRemoteDataSource danmakuDataSource;

    setUp(() {
      final detailJson = loadJson('video_detail.json');
      final relationJson = loadJson('video_relation.json');
      final relatedJson = loadJson('related_videos.json');
      final replyJson = loadJson('reply_list.json');
      final replyReplyJson = loadJson('reply_reply_list.json');

      mockNetwork = MockNetworkVideoDataSource(
        videoDetailJson: detailJson as Map<String, dynamic>,
        videoRelationJson: relationJson as Map<String, dynamic>,
        relatedVideosJson:
            (relatedJson as Map<String, dynamic>)['data'] as List<dynamic>,
        replyListJson: replyJson as Map<String, dynamic>,
        replyReplyListJson: replyReplyJson as Map<String, dynamic>,
        danmakuDocument: const NetworkBiliDanmakuDocument(
          chatServer: 'chat.bilibili.com',
          chatId: 137646676,
          mission: 0,
          maxLimit: 500,
          state: 0,
          realName: 0,
          comments: [
            NetworkBiliDanmaku(
              startSeconds: 1.5,
              mode: 5,
              fontSize: 25,
              color: 0xFFFFFF,
              sentAt: 1,
              pool: 0,
              userHash: 'hash',
              rowId: 7,
              content: '顶部弹幕',
            ),
          ],
        ),
      );

      detailDataSource = BiliVideoDetailRemoteDataSource(network: mockNetwork);
      commentDataSource = BiliVideoCommentRemoteDataSource(
        network: mockNetwork,
      );
      danmakuDataSource = BiliDanmakuRemoteDataSource(network: mockNetwork);
    });

    test(
      'getVideoDetail maps detail, owner, relation, and related videos',
      () async {
        final result = await detailDataSource.getVideoDetail('BV1GJ411x7vy');
        expect(result.isSuccess(), isTrue);

        final detail = (result as dynamic).success;
        expect(detail.video.id, equals('BV1GJ411x7vy'));
        expect(detail.video.title, isNotEmpty);
        expect(detail.creator, isNotNull);
        expect(detail.creator?.name, isNotEmpty);
        expect(detail.relatedVideos, isNotEmpty);
      },
    );

    test(
      'getVideoDetail maps player view_points into sorted chapters',
      () async {
        mockNetwork.playerInfoJson = {
          'aid': 1,
          'bvid': 'BV1GJ411x7vy',
          'cid': 1,
          'view_points': [
            {'from': 90, 'to': 120, 'content': '第三段'},
            {'from': 10, 'to': 40, 'content': '开场'},
            {'from': 50, 'to': 80, 'content': '   '},
            {'to': 80, 'content': '缺起点'},
            {'from': 30.6, 'to': 45, 'content': '中段'},
          ],
        };

        final result = await detailDataSource.getVideoDetail('BV1GJ411x7vy');
        expect(result.isSuccess(), isTrue);

        final chapters = (result as dynamic).success.chapters as List;
        // 空白标题与缺起点的看点被丢掉，其余按起点升序。
        expect(
          chapters
              .map((c) => (c.startSeconds as int, c.title as String))
              .toList(),
          [(10, '开场'), (31, '中段'), (90, '第三段')],
        );
        // 查询用的是第一个分 P 的 cid。
        final detailJson =
            loadJson('video_detail.json') as Map<String, dynamic>;
        final firstCid =
            (detailJson['data'] as Map<String, dynamic>)['pages'][0]['cid']
                as int;
        expect(mockNetwork.playerInfoCalls, [('BV1GJ411x7vy', firstCid)]);
      },
    );

    test(
      'getVideoDetail degrades to empty chapters when player/v2 fails',
      () async {
        mockNetwork.playerInfoError = Exception('player unavailable');

        final result = await detailDataSource.getVideoDetail('BV1GJ411x7vy');
        expect(result.isSuccess(), isTrue);
        expect((result as dynamic).success.chapters, isEmpty);
      },
    );

    test('getVideoComments maps reply list to VideoComment page', () async {
      final result = await commentDataSource.getVideoComments(
        'BV1GJ411x7vy',
        page: 1,
      );
      expect(result.isSuccess(), isTrue);

      final page = (result as dynamic).success;
      expect(page.number, equals(1));
      expect(page.data, isNotEmpty);
      expect(page.data.first.authorName, isNotEmpty);
    });

    test('getDanmaku maps the XML DTO to neutral timed comments', () async {
      final result = await danmakuDataSource.getDanmaku('BV1GJ411x7vy');

      expect(result.isSuccess(), isTrue);
      final comments =
          (result as Success<List<DanmakuComment>, Exception>).success;
      expect(comments, hasLength(1));
      expect(comments.single.startTime, const Duration(milliseconds: 1500));
      expect(comments.single.mode, DanmakuMode.top);
      expect(comments.single.colorArgb, 0xFFFFFFFF);
      expect(comments.single.content, '顶部弹幕');
    });

    test('getDanmaku sanitizes control characters in comment content and filters out empty items', () async {
      final customNetwork = MockNetworkVideoDataSource(
        videoDetailJson: loadJson('video_detail.json') as Map<String, dynamic>,
        videoRelationJson:
            loadJson('video_relation.json') as Map<String, dynamic>,
        relatedVideosJson:
            (loadJson('related_videos.json') as Map<String, dynamic>)['data']
                as List<dynamic>,
        replyListJson: loadJson('reply_list.json') as Map<String, dynamic>,
        replyReplyListJson:
            loadJson('reply_reply_list.json') as Map<String, dynamic>,
        danmakuDocument: const NetworkBiliDanmakuDocument(
          chatServer: 'chat.bilibili.com',
          chatId: 137646676,
          mission: 0,
          maxLimit: 500,
          state: 0,
          realName: 0,
          comments: [
            NetworkBiliDanmaku(
              startSeconds: 1.0,
              mode: 1,
              fontSize: 25,
              color: 0xFFFFFF,
              sentAt: 1,
              pool: 0,
              userHash: 'hash1',
              rowId: 1,
              content: '  弹幕\r\n\x00内容  ',
            ),
            NetworkBiliDanmaku(
              startSeconds: 2.0,
              mode: 1,
              fontSize: 25,
              color: 0xFFFFFF,
              sentAt: 2,
              pool: 0,
              userHash: 'hash2',
              rowId: 2,
              content: '\r\n\x00\x1F  ',
            ),
          ],
        ),
      );
      final customDanmakuDataSource = BiliDanmakuRemoteDataSource(
        network: customNetwork,
      );

      final result = await customDanmakuDataSource.getDanmaku('BV1GJ411x7vy');
      expect(result.isSuccess(), isTrue);
      final comments =
          (result as Success<List<DanmakuComment>, Exception>).success;
      expect(comments, hasLength(1));
      expect(comments.single.content, '弹幕内容');
    });

    test('getVideoCommentReplies maps and paginates nested replies', () async {
      final result = await commentDataSource.getVideoCommentReplies(
        '80431228',
        '2202965009',
        page: 2,
      );
      expect(result.isSuccess(), isTrue);

      final page = (result as dynamic).success;
      expect(page.number, equals(2));
      expect(page.totalPages, equals(1));
      expect(page.data, isEmpty);
      expect(mockNetwork.replyReplyCalls, [(80431228, 2202965009, 1, 2)]);
    });

    test('getVideoDetail sanitizes control characters and returns Result.error for empty ID', () async {
      final sanitizedResult = await detailDataSource.getVideoDetail(
        'BV1GJ411x7vy\r\n\x00',
      );
      expect(sanitizedResult.isSuccess(), isTrue);

      final emptyResult = await detailDataSource.getVideoDetail('  \r\n\x00 ');
      expect(emptyResult.isError(), isTrue);
    });

    test('getVideoComments sanitizes control characters and returns Result.error for empty ID', () async {
      final sanitizedResult = await commentDataSource.getVideoComments(
        'BV1GJ411x7vy\r\n\x00',
      );
      expect(sanitizedResult.isSuccess(), isTrue);

      final emptyResult = await commentDataSource.getVideoComments(
        '  \r\n\x00 ',
      );
      expect(emptyResult.isError(), isTrue);
    });

    test(
      'normalizes http:// and // URLs in video detail and comments to https://',
      () async {
        final detailRes = await detailDataSource.getVideoDetail('BV1GJ411x7vy');
        expect(detailRes.isSuccess(), isTrue);
        final detail = (detailRes as dynamic).success;
        expect(detail.video.thumbnailUrl, startsWith('https://'));

        final commentRes = await commentDataSource.getVideoComments(
          'BV1GJ411x7vy',
        );
        expect(commentRes.isSuccess(), isTrue);
        final page = (commentRes as dynamic).success;
        expect(page.data.first.authorAvatar, startsWith('https://'));
      },
    );
  });
}

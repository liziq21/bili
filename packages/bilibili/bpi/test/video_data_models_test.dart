import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture(String name) {
    final file = File('testing/$name');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'Fixture file testing/$name should exist',
    );
    final content = file.readAsStringSync();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  group('Video Detail & Relation Models', () {
    test('parses real video_detail.json correctly', () {
      final json = loadFixture('video_detail.json');
      final baseRes = BaseResponse.fromJson(json);

      expect(baseRes.code, equals(0));
      expect(baseRes.message, equals('OK'));
      expect(baseRes.data, isNotNull);

      final video = baseRes.data;
      expect(video.bvid, equals('BV1GJ411x7vy'));
      expect(video.aid, equals(80431228));
      expect(video.cid, equals(137646676));
      expect(video.title, equals('教科书上的道具操作都有'));
      expect(video.owner?.name, equals('风悄笔落'));
      expect(video.stat?.view, greaterThan(0));
      expect(video.dimension?.width, equals(1280));
      expect(video.dimension?.height, equals(720));
      expect(video.isPageReversed, isFalse);
    });

    test('parses real video_relation.json correctly', () {
      final json = loadFixture('video_relation.json');
      if (json['data'] is Map<String, dynamic>) {
        final relation = NetworkVideoRelation.fromJson(
          json['data'] as Map<String, dynamic>,
        );
        expect(relation, isNotNull);
      } else {
        expect(json['code'], equals(-101));
      }

      final mockRelation = NetworkVideoRelation.fromJson({
        'attention': true,
        'favorite': false,
        'season_fav': false,
        'like': true,
        'dislike': false,
        'coin': 1,
      });
      expect(mockRelation.attention, isTrue);
      expect(mockRelation.like, isTrue);
      expect(mockRelation.favorite, isFalse);
      expect(mockRelation.coin, equals(1));
    });
  });

  group('Related Videos Model', () {
    test('parses real related_videos.json correctly', () {
      final json = loadFixture('related_videos.json');
      expect(json['code'], equals(0));
      final dataList = json['data'] as List;
      final list = NetworkRelatedVideosList.fromJson({'items': dataList});

      expect(list.items, isNotEmpty);
      final item = list.items.first;
      expect(item.aid, greaterThan(0));
      expect(item.bvid, isNotEmpty);
      expect(item.owner, isNotNull);
    });
  });

  group('PlayUrl Model', () {
    test('parses real play_url.json correctly', () {
      final json = loadFixture('play_url.json');
      expect(json['code'], equals(0));
      final data = json['data'] as Map<String, dynamic>;
      final playUrl = NetworkPlayUrl.fromJson(data);

      expect(playUrl.quality, greaterThan(0));
      expect(playUrl.format, isNotNull);
      expect(playUrl.dash, isNotNull);
      expect(playUrl.dash?.video, isNotEmpty);
      expect(playUrl.dash?.audio, isNotEmpty);
      final videoStream = playUrl.dash!.video!.first;
      expect(videoStream.playUrls, isNotEmpty);
    });
  });

  group('Reply Models', () {
    test('parses real reply_list_main.json correctly', () {
      final json = loadFixture('reply_list_main.json');
      expect(json['code'], equals(0));
      final data = json['data'] as Map<String, dynamic>;
      final replyData = NetworkReplyData.fromJson(data);

      expect(replyData.cursor, isNotNull);
      expect(replyData.replies, isNotNull);
    });

    test('parses real reply_list.json correctly', () {
      final json = loadFixture('reply_list.json');
      expect(json['code'], equals(0));
      final data = json['data'] as Map<String, dynamic>;
      final replyData = NetworkReplyData.fromJson(data);

      expect(replyData.replies, isNotNull);
      if (replyData.replies!.isNotEmpty) {
        final firstReply = replyData.replies!.first;
        expect(firstReply.rpid, greaterThan(0));
        expect(firstReply.member, isNotNull);
        expect(firstReply.content, isNotNull);
        expect(firstReply.content?.message, isNotEmpty);
      }
    });

    test('parses real reply_reply_list.json correctly', () {
      final json = loadFixture('reply_reply_list.json');
      expect(json['code'], equals(0));
      final data = json['data'] as Map<String, dynamic>;
      final replyData = NetworkReplyReplyData.fromJson(data);

      expect(replyData, isNotNull);
    });
  });

  group('Staff (联合创作)', () {
    // 联合创作视频的 /x/web-interface/view 响应里 staff 条目的 vip 与
    // official 是对象或 null，follower 可能缺省；按必填 int 解码会让整条
    // 详情响应解析失败，页面连标题都显示不出来。
    test('parses staff entries whose vip and official are null', () {
      final video = VideoDetailData.fromJson({
        'bvid': 'BV1atse6EEfx',
        'aid': 1,
        'videos': 1,
        'tid': 1,
        'tname': 't',
        'copyright': 1,
        'pic': 'https://example/pic.jpg',
        'title': 'title',
        'pubdate': 1700000000,
        'ctime': 1700000000,
        'desc': 'desc',
        'state': 0,
        'duration': 60,
        'cid': 1,
        'owner': {'mid': 1, 'name': 'up', 'face': 'https://example/face.jpg'},
        'pages': [
          {
            'cid': 1,
            'page': 1,
            'from': 'vupload',
            'part': 'p1',
            'duration': 60,
          },
        ],
        'staff': [
          {
            'mid': 652239032,
            'title': 'UP主',
            'name': 'IGN中国',
            'face': 'https://example/staff.jpg',
            'vip': null,
            'official': null,
            'follower': 2109229,
            'label_style': 0,
          },
          {
            'mid': 1328260,
            'title': '参演',
            'name': '某某',
            'face': 'https://example/staff2.jpg',
          },
        ],
      });

      expect(video.staff, hasLength(2));
      expect(video.staff!.first.mid, equals(652239032));
      expect(video.staff!.first.follower, equals(2109229));
      expect(video.staff!.last.follower, isNull);
    });
  });
}

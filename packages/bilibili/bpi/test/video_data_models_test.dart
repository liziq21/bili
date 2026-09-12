import 'package:bpi/bpi.dart';
import 'package:test/test.dart';

void main() {
  group('Video Detail & Relation Models', () {
    test('deserializes VideoDetailData correctly', () {
      final json = {
        'bvid': 'BV1xx411c7mD',
        'aid': 170001,
        'videos': 1,
        'copyright': 1,
        'pic': 'http://i0.hdslb.com/bfs/archive/test.jpg',
        'title': 'Test Video Title',
        'pubdate': 1600000000,
        'ctime': 1600000000,
        'desc': 'Test video description',
        'duration': 120,
        'cid': 10001,
        'owner': {
          'mid': 12345,
          'name': 'Test UP',
          'face': 'http://i0.hdslb.com/bfs/face/test.jpg',
        },
        'stat': {
          'aid': 170001,
          'view': 1000,
          'danmaku': 50,
          'reply': 20,
          'favorite': 10,
          'coin': 5,
          'share': 2,
          'like': 100,
        },
        'pages': [
          {
            'cid': 10001,
            'page': 1,
            'from': 'vupload',
            'part': 'Part 1',
            'duration': 120,
          }
        ],
      };

      final data = VideoDetailData.fromJson(json);
      expect(data.bvid, equals('BV1xx411c7mD'));
      expect(data.aid, equals(170001));
      expect(data.title, equals('Test Video Title'));
      expect(data.owner?.name, equals('Test UP'));
      expect(data.stat?.like, equals(100));
      expect(data.pages?.length, equals(1));
      expect(data.pages?.first.part, equals('Part 1'));
    });

    test('deserializes NetworkVideoRelation correctly', () {
      final json = {
        'attention': true,
        'favorite': false,
        'season_fav': false,
        'like': true,
        'dislike': false,
        'coin': 1,
      };

      final relation = NetworkVideoRelation.fromJson(json);
      expect(relation.attention, isTrue);
      expect(relation.like, isTrue);
      expect(relation.favorite, isFalse);
      expect(relation.coin, equals(1));
    });
  });

  group('Related Videos Model', () {
    test('deserializes NetworkRelatedVideosList correctly', () {
      final json = {
        'items': [
          {
            'aid': 20002,
            'bvid': 'BV1234567890',
            'title': 'Related Video 1',
            'pic': 'http://i0.hdslb.com/bfs/archive/rel.jpg',
            'duration': 300,
            'owner': {
              'mid': 67890,
              'name': 'Related UP',
              'face': 'http://i0.hdslb.com/bfs/face/rel.jpg',
            },
          }
        ]
      };

      final list = NetworkRelatedVideosList.fromJson(json);
      expect(list.items.length, equals(1));
      final item = list.items.first;
      expect(item.aid, equals(20002));
      expect(item.bvid, equals('BV1234567890'));
      expect(item.owner?.name, equals('Related UP'));
    });
  });

  group('PlayUrl Model', () {
    test('deserializes NetworkPlayUrl with Dash correctly', () {
      final json = {
        'quality': 80,
        'format': 'flv720',
        'timelength': 120000,
        'dash': {
          'duration': 120,
          'minBufferTime': 1.5,
          'video': [
            {
              'id': 80,
              'baseUrl': 'http://stream.hdslb.com/video80.m4s',
              'bandwidth': 1500000,
              'codecs': 'avc1.640028',
              'width': 1920,
              'height': 1080,
            }
          ],
          'audio': [
            {
              'id': 30280,
              'baseUrl': 'http://stream.hdslb.com/audio30280.m4s',
              'bandwidth': 128000,
              'codecs': 'mp4a.40.2',
            }
          ]
        }
      };

      final playUrl = NetworkPlayUrl.fromJson(json);
      expect(playUrl.quality, equals(80));
      expect(playUrl.dash?.video?.length, equals(1));
      expect(playUrl.dash?.video?.first.baseUrl, contains('video80.m4s'));
      expect(playUrl.dash?.audio?.first.baseUrl, contains('audio30280.m4s'));
    });
  });

  group('Reply Models', () {
    test('deserializes NetworkReplyData correctly', () {
      final json = {
        'cursor': {
          'is_end': false,
          'next': 2,
          'all_count': 100,
        },
        'replies': [
          {
            'rpid': 1001,
            'oid': 170001,
            'type': 1,
            'mid': 55555,
            'like': 42,
            'member': {
              'mid': '55555',
              'uname': 'Commenter',
              'sex': '保密',
              'sign': 'Hello',
              'avatar': 'http://i0.hdslb.com/bfs/face/commenter.jpg',
            },
            'content': {
              'message': 'Great video!',
            }
          }
        ]
      };

      final replyData = NetworkReplyData.fromJson(json);
      expect(replyData.cursor?.allCount, equals(100));
      expect(replyData.replies?.length, equals(1));
      final reply = replyData.replies!.first;
      expect(reply.rpid, equals(1001));
      expect(reply.member?.uname, equals('Commenter'));
      expect(reply.content?.message, equals('Great video!'));
    });

    test('deserializes NetworkReplyReplyData correctly', () {
      final json = {
        'page': {
          'num': 1,
          'size': 20,
          'count': 5,
        },
        'replies': [
          {
            'rpid': 2001,
            'oid': 170001,
            'type': 1,
            'mid': 66666,
            'root': 1001,
            'member': {
              'mid': '66666',
              'uname': 'SubCommenter',
              'sex': '男',
              'sign': '',
              'avatar': 'http://i0.hdslb.com/bfs/face/sub.jpg',
            },
            'content': {
              'message': 'Sub reply',
            }
          }
        ]
      };

      final replyData = NetworkReplyReplyData.fromJson(json);
      expect(replyData.page?.count, equals(5));
      expect(replyData.replies?.first.rpid, equals(2001));
      expect(replyData.replies?.first.content?.message, equals('Sub reply'));
    });
  });
}

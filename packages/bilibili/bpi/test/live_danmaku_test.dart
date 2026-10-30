import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:bpi/bpi.dart';

Uint8List _createTestPacket(
  Uint8List body, {
  required int opCode,
  int ver = 0,
}) {
  final headerLen = 16;
  final packetLen = headerLen + body.length;
  final buffer = ByteData(packetLen);
  buffer.setUint32(0, packetLen, Endian.big);
  buffer.setUint16(4, headerLen, Endian.big);
  buffer.setUint16(6, ver, Endian.big);
  buffer.setUint32(8, opCode, Endian.big);
  buffer.setUint32(12, 0, Endian.big);
  final result = Uint8List(packetLen);
  result.setRange(0, headerLen, buffer.buffer.asUint8List());
  result.setRange(headerLen, packetLen, body);
  return result;
}

void main() {
  group('LiveDanmakuPacket', () {
    test('parses auth packet correctly', () {
      final packet = LiveDanmakuPacket.createAuthPacket(
        roomId: 123456,
        token: 'test_token_abc',
        protocol: 1,
        platform: 'web',
      );

      expect(packet.length, greaterThan(16)); // header + body
      final parsed = LiveDanmakuPacket.fromBytes(packet);
      // Both auth and authReply have opCode 7; fromValue returns first match (authReply)
      expect(parsed.opCode, equals(LiveDanmakuOpCode.authReply));
      expect(parsed.payload.isNotEmpty, isTrue);
    });

    test('parses heartbeat packet correctly', () {
      final packet = LiveDanmakuPacket.createHeartbeatPacket();

      expect(packet.length, equals(16)); // header only, no body
      final parsed = LiveDanmakuPacket.fromBytes(packet);
      expect(parsed.opCode, equals(LiveDanmakuOpCode.heartbeat));
      expect(parsed.payload, isEmpty);
    });

    test('parses notify packet with zlib compression (ver=2)', () {
      // Create a sample notify payload
      final notifyJson = {
        'cmd': 'DANMU_MSG',
        'data': {
          'info': [
            [1, 25, 16777215, 1234567890, 'rnd123'],
            '测试弹幕内容',
            [78901, 'test_user', false, false, 0, 0, '', 0, '', 'face.jpg'],
            ['粉丝牌', 10],
            [20],
          ],
        },
      };
      final jsonBytes = utf8.encode(jsonEncode(notifyJson));
      final compressed = Uint8List.fromList(ZLibCodec().encode(jsonBytes));
      final packet = _createTestPacket(compressed, opCode: 5, ver: 2);

      final parsed = LiveDanmakuPacket.fromBytes(packet);
      expect(parsed.opCode, equals(LiveDanmakuOpCode.notify));
      expect(parsed.payload, isNotEmpty);
    });

    test('rejects packet with length mismatch', () {
      final packet = LiveDanmakuPacket.createAuthPacket(
        roomId: 123456,
        token: 'test',
      );
      // Corrupt packet length
      final corrupted = Uint8List.fromList(packet);
      corrupted[0] = 0xFF; // Wrong packet length

      expect(
        () => LiveDanmakuPacket.fromBytes(corrupted),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects packet too short for header', () {
      expect(
        () => LiveDanmakuPacket.fromBytes(Uint8List(10)),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('LiveDanmakuMessage', () {
    test('parses DANMU_MSG correctly', () {
      final json = {
        'cmd': 'DANMU_MSG',
        'data': {
          'info': [
            [1, 25, 16777215, 1234567890, 'rnd123'],
            '测试弹幕内容',
            [78901, 'test_user', false, false, 0, 0, '', 0, '', 'face.jpg'],
            ['粉丝牌', 10],
            [20],
          ],
        },
      };

      final message = LiveDanmakuMessage.fromJson(json);
      expect(message.cmd, equals('DANMU_MSG'));
      expect(message.isDanmaku, isTrue);
      expect(message.isGift, isFalse);

      final comment = message.asComment();
      expect(comment, isNotNull);
      expect(comment!.content, equals('测试弹幕内容'));
      expect(comment.userId, equals(78901));
      expect(comment.username, equals('test_user'));
      expect(comment.medalName, equals('粉丝牌'));
      expect(comment.medalLevel, equals(10));
      expect(comment.userLevel, equals(20));
      expect(comment.guardLevel, equals(0));
    });

    test('parses SEND_GIFT correctly', () {
      final json = {
        'cmd': 'SEND_GIFT',
        'data': {
          'giftName': '小心心',
          'num': 1,
          'uname': 'gift_user',
          'uid': 111222,
        },
      };

      final message = LiveDanmakuMessage.fromJson(json);
      expect(message.cmd, equals('SEND_GIFT'));
      expect(message.isGift, isTrue);
      expect(message.isDanmaku, isFalse);
      expect(message.asComment(), isNull);
    });

    test('handles missing fields gracefully', () {
      final json = {
        'cmd': 'DANMU_MSG',
        'data': {
          'info': [
            [],
            '内容',
            [123, 'user'],
            null,
            [],
          ],
        },
      };

      final message = LiveDanmakuMessage.fromJson(json);
      final comment = message.asComment();
      expect(comment, isNotNull);
      expect(comment!.content, equals('内容'));
      expect(comment.userId, equals(123));
      expect(comment.username, equals('user'));
      expect(comment.medalName, isNull);
      expect(comment.medalLevel, isNull);
    });

    test('unknown command does not throw', () {
      final json = {'cmd': 'UNKNOWN_CMD', 'data': {}};

      final message = LiveDanmakuMessage.fromJson(json);
      expect(message.cmd, equals('UNKNOWN_CMD'));
      expect(message.isDanmaku, isFalse);
    });
  });

  group('LiveDanmakuAuth', () {
    test('creates from room detail with roomInfo', () {
      final detail = NetworkLiveRoomDetail(
        roomInfo: NetworkLiveRoomInfo(
          roomId: 123456,
          uid: 78901,
          title: 'Test Live',
          liveStatus: 1,
        ),
        anchorInfo: null,
        watchedShow: null,
      );

      final auth = LiveDanmakuAuth.fromRoomDetail(detail);
      expect(auth.roomId, equals(123456));
      expect(auth.token, equals(''));
      expect(auth.hostList, equals(['broadcastlv.chat.bilibili.com']));
    });

    test('handles missing roomInfo', () {
      final detail = NetworkLiveRoomDetail(
        roomInfo: null,
        anchorInfo: null,
        watchedShow: null,
      );

      final auth = LiveDanmakuAuth.fromRoomDetail(detail);
      expect(auth.roomId, equals(0));
    });
  });

  group('LiveDanmakuComment', () {
    test('extracts all fields from complete info array', () {
      final data = {
        'info': [
          [1, 25, 16777215, 1234567890, 'rnd123'],
          '完整弹幕内容',
          [78901, 'test_user', false, false, 0, 0, '', 0, '', 'face.jpg'],
          ['粉丝牌', 10],
          [20],
        ],
      };

      final comment = LiveDanmakuComment.fromData(data);
      expect(comment.content, equals('完整弹幕内容'));
      expect(comment.userId, equals(78901));
      expect(comment.username, equals('test_user'));
      expect(comment.userFace, equals('face.jpg'));
      expect(comment.medalName, equals('粉丝牌'));
      expect(comment.medalLevel, equals(10));
      expect(comment.userLevel, equals(20));
      expect(comment.guardLevel, equals(0));
      expect(comment.timestamp, equals(1234567890));
    });

    test('handles missing optional arrays', () {
      final data = {
        'info': [
          [1, 25, 16777215, 1234567890, 'rnd123'],
          '简单内容',
          [78901, 'test_user'],
        ],
      };

      final comment = LiveDanmakuComment.fromData(data);
      expect(comment.content, equals('简单内容'));
      expect(comment.userId, equals(78901));
      expect(comment.username, equals('test_user'));
      expect(comment.medalName, isNull);
      expect(comment.medalLevel, isNull);
      expect(comment.userLevel, equals(0));
      expect(comment.guardLevel, equals(0));
    });

    test('handles empty info array', () {
      final data = {'info': []};
      final comment = LiveDanmakuComment.fromData(data);
      expect(comment.content, equals(''));
      expect(comment.userId, equals(0));
      expect(comment.username, equals(''));
    });
  });
}

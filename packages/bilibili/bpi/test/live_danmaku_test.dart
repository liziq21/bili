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

  group('LiveDanmakuFrame encoding/decoding', () {
    test('encodes and decodes handshake request frame', () {
      final frame = LiveDanmakuFrame(
        opCode: LiveDanmakuOpCode.handshakeRequest,
        body: utf8.encode(
          '{"roomid":123,"uid":0,"protover":2,"platform":"web","type":2,"key":"test_token"}',
        ),
        protocolVersion: LiveDanmakuProtocolVersion.v2,
        sequenceId: 1,
      );

      final encoded = frame.encode();
      final decoded = LiveDanmakuFrame.decode(encoded);

      expect(decoded.opCode, equals(LiveDanmakuOpCode.handshakeRequest));
      expect(decoded.protocolVersion, equals(LiveDanmakuProtocolVersion.v2));
      expect(decoded.sequenceId, equals(1));
      expect(decoded.body, equals(frame.body));
    });

    test('encodes and decodes heartbeat frame', () {
      final frame = LiveDanmakuFrame(
        opCode: LiveDanmakuOpCode.heartbeat,
        body: [0, 0, 0, 5], // sequenceId = 5
        protocolVersion: LiveDanmakuProtocolVersion.v2,
        sequenceId: 5,
      );

      final encoded = frame.encode();
      final decoded = LiveDanmakuFrame.decode(encoded);

      expect(decoded.opCode, equals(LiveDanmakuOpCode.heartbeat));
      expect(decoded.sequenceId, equals(5));
    });

    test('decodes handshake response frame from fixture', () {
      final fixture = loadFixture('live_danmaku_frames.json');
      final hs = fixture['handshake_response'] as Map<String, dynamic>;
      final bodyBytes = utf8.encode(jsonEncode(hs['body']));
      final frame = LiveDanmakuFrame(
        opCode: LiveDanmakuOpCode.fromValue(hs['op_code'] as int)!,
        body: bodyBytes,
        protocolVersion: LiveDanmakuProtocolVersion.values.firstWhere(
          (v) => v.value == hs['protocol_version'],
        ),
        sequenceId: hs['sequence_id'] as int,
      );

      final encoded = frame.encode();
      final decoded = LiveDanmakuFrame.decode(encoded);

      expect(decoded.opCode, equals(LiveDanmakuOpCode.handshakeResponse));
      final json =
          jsonDecode(utf8.decode(decoded.body)) as Map<String, dynamic>;
      expect(json['code'], equals(0));
    });
  });

  group('LiveDanmakuOpCode', () {
    test('fromValue maps known codes', () {
      expect(
        LiveDanmakuOpCode.fromValue(2),
        equals(LiveDanmakuOpCode.heartbeat),
      );
      expect(
        LiveDanmakuOpCode.fromValue(3),
        equals(LiveDanmakuOpCode.heartbeatResponse),
      );
      expect(
        LiveDanmakuOpCode.fromValue(5),
        equals(LiveDanmakuOpCode.notification),
      );
      expect(
        LiveDanmakuOpCode.fromValue(6),
        equals(LiveDanmakuOpCode.disconnect),
      );
      expect(
        LiveDanmakuOpCode.fromValue(7),
        equals(LiveDanmakuOpCode.handshakeRequest),
      );
      expect(
        LiveDanmakuOpCode.fromValue(8),
        equals(LiveDanmakuOpCode.handshakeResponse),
      );
      expect(LiveDanmakuOpCode.fromValue(99), isNull);
    });
  });

  group('LiveDanmakuMessageType', () {
    test('fromString maps known types', () {
      expect(
        LiveDanmakuMessageType.fromString('DANMU_MSG'),
        equals(LiveDanmakuMessageType.danmaku),
      );
      expect(
        LiveDanmakuMessageType.fromString('SEND_GIFT'),
        equals(LiveDanmakuMessageType.gift),
      );
      expect(
        LiveDanmakuMessageType.fromString('GUARD_BUY'),
        equals(LiveDanmakuMessageType.guardBuy),
      );
      expect(
        LiveDanmakuMessageType.fromString('SUPER_CHAT_MESSAGE'),
        equals(LiveDanmakuMessageType.superChat),
      );
      expect(
        LiveDanmakuMessageType.fromString('INTERACT_WORD'),
        equals(LiveDanmakuMessageType.entry),
      );
      expect(
        LiveDanmakuMessageType.fromString('WATCHED_CHANGE'),
        equals(LiveDanmakuMessageType.like),
      );
      expect(
        LiveDanmakuMessageType.fromString('ROOM_CHANGE'),
        equals(LiveDanmakuMessageType.roomChange),
      );
      expect(
        LiveDanmakuMessageType.fromString('UNKNOWN_CMD'),
        equals(LiveDanmakuMessageType.unknown),
      );
    });
  });

  group('LiveDanmakuMode', () {
    test('fromValue maps known modes', () {
      expect(LiveDanmakuMode.fromValue(1), equals(LiveDanmakuMode.scrolling));
      expect(LiveDanmakuMode.fromValue(4), equals(LiveDanmakuMode.top));
      expect(LiveDanmakuMode.fromValue(5), equals(LiveDanmakuMode.bottom));
      expect(LiveDanmakuMode.fromValue(6), equals(LiveDanmakuMode.reverse));
      expect(LiveDanmakuMode.fromValue(7), equals(LiveDanmakuMode.special));
      expect(LiveDanmakuMode.fromValue(99), equals(LiveDanmakuMode.scrolling));
    });
  });

  group('LiveDanmakuHandshakeRequest', () {
    test('toJson produces correct structure', () {
      final request = LiveDanmakuHandshakeRequest(
        roomId: 21144080,
        uid: 0,
        token: 'test_token',
        protocolVersion: LiveDanmakuProtocolVersion.v2,
      );

      final json = request.toJson();
      expect(json['roomid'], equals(21144080));
      expect(json['uid'], equals(0));
      expect(json['protover'], equals(2));
      expect(json['platform'], equals('web'));
      expect(json['type'], equals(2));
      expect(json['key'], equals('test_token'));
    });
  });

  group('LiveDanmakuHandshakeResponse', () {
    test('fromJson parses success response', () {
      final response = LiveDanmakuHandshakeResponse.fromJson({
        'code': 0,
        'msg': 'success',
      });
      expect(response.code, equals(0));
      expect(response.message, equals('success'));
      expect(response.isSuccess, isTrue);
    });

    test('fromJson parses failure response', () {
      final response = LiveDanmakuHandshakeResponse.fromJson({
        'code': -101,
        'msg': 'token invalid',
      });
      expect(response.code, equals(-101));
      expect(response.message, equals('token invalid'));
      expect(response.isSuccess, isFalse);
    });

    test('fromJson handles missing fields', () {
      final response = LiveDanmakuHandshakeResponse.fromJson({});
      expect(response.code, equals(-1));
      expect(response.message, isNull);
      expect(response.isSuccess, isFalse);
    });
  });

  group('LiveDanmakuMessage parsing', () {
    test('parses danmaku message from fixture', () {
      final fixture = loadFixture('live_danmaku_frames.json');
      final dm = fixture['danmaku_notification'] as Map<String, dynamic>;
      final payload = dm['body'] as Map<String, dynamic>;

      final message = LiveDanmakuMessage(
        type: LiveDanmakuMessageType.fromString(payload['cmd'] as String),
        payload: payload,
        rawType: payload['cmd'] as String,
      );

      expect(message.type, equals(LiveDanmakuMessageType.danmaku));
      expect(message.rawType, equals('DANMU_MSG'));

      final comment = message.comment;
      expect(comment, isNotNull);
      expect(comment!.content, equals('Hello World'));
      expect(comment.mode, equals(LiveDanmakuMode.scrolling));
      expect(comment.fontSize, equals(25.0));
      expect(comment.colorArgb, equals(0xFFFFFFFF));
      expect(comment.startTime.inSeconds, equals(1700000000));
    });

    test('parses gift message', () {
      final fixture = loadFixture('live_danmaku_frames.json');
      final gift = fixture['gift_notification'] as Map<String, dynamic>;
      final payload = gift['body'] as Map<String, dynamic>;

      final message = LiveDanmakuMessage(
        type: LiveDanmakuMessageType.fromString(payload['cmd'] as String),
        payload: payload,
        rawType: payload['cmd'] as String,
      );

      expect(message.type, equals(LiveDanmakuMessageType.gift));
      expect(message.comment, isNull);
    });

    test('parses entry message', () {
      final fixture = loadFixture('live_danmaku_frames.json');
      final entry = fixture['entry_notification'] as Map<String, dynamic>;
      final payload = entry['body'] as Map<String, dynamic>;

      final message = LiveDanmakuMessage(
        type: LiveDanmakuMessageType.fromString(payload['cmd'] as String),
        payload: payload,
        rawType: payload['cmd'] as String,
      );

      expect(message.type, equals(LiveDanmakuMessageType.entry));
    });

    test('returns unknown for unrecognized type', () {
      final message = LiveDanmakuMessage(
        type: LiveDanmakuMessageType.unknown,
        payload: {'cmd': 'UNKNOWN_CMD'},
        rawType: 'UNKNOWN_CMD',
      );

      expect(message.type, equals(LiveDanmakuMessageType.unknown));
      expect(message.comment, isNull);
    });
  });

  group('LiveDanmakuComment', () {
    test('constructs with all fields', () {
      final comment = LiveDanmakuComment(
        content: 'Test comment',
        mode: LiveDanmakuMode.top,
        fontSize: 30.0,
        colorArgb: 0xFFFF0000,
        startTime: const Duration(seconds: 120),
        userName: 'testuser',
        userId: 12345,
        isAdmin: true,
        isVip: false,
        medalName: 'Fan Medal',
        medalLevel: 10,
      );

      expect(comment.content, equals('Test comment'));
      expect(comment.mode, equals(LiveDanmakuMode.top));
      expect(comment.fontSize, equals(30.0));
      expect(comment.colorArgb, equals(0xFFFF0000));
      expect(comment.startTime, equals(const Duration(seconds: 120)));
      expect(comment.userName, equals('testuser'));
      expect(comment.userId, equals(12345));
      expect(comment.isAdmin, isTrue);
      expect(comment.isVip, isFalse);
      expect(comment.medalName, equals('Fan Medal'));
      expect(comment.medalLevel, equals(10));
    });
  });

  group('LiveDanmakuFrame protocol version 1', () {
    test('encodes and decodes with v1', () {
      final frame = LiveDanmakuFrame(
        opCode: LiveDanmakuOpCode.notification,
        body: utf8.encode('{"cmd":"TEST"}'),
        protocolVersion: LiveDanmakuProtocolVersion.v1,
        sequenceId: 1,
      );

      final encoded = frame.encode();
      final decoded = LiveDanmakuFrame.decode(encoded);

      expect(decoded.protocolVersion, equals(LiveDanmakuProtocolVersion.v1));
    });
  });
}

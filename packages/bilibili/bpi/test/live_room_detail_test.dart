import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/live_room_detail.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('parses real live_room_detail.json fixture correctly', () {
    final json = loadFixture();
    expect(json['code'], equals(0));
    final data = json['data'] as Map<String, dynamic>;
    final detail = NetworkLiveRoomDetail.fromJson(data);

    expect(detail.roomInfo?.roomId, equals(21144080));
    expect(detail.roomInfo?.uid, equals(392836434));
    expect(detail.roomInfo?.title, contains('广州TTG vs 深圳DYG'));
    expect(detail.roomInfo?.liveStatus, equals(1));
    expect(detail.roomInfo?.areaName, equals('游戏赛事'));
    expect(detail.anchorInfo, isNotNull);
    expect(detail.anchorInfo?.baseInfo?.uname, equals('哔哩哔哩王者荣耀赛事'));
  });

  group('missing non-core fields', () {
    test('room_info absent leaves the model empty instead of throwing', () {
      final detail = NetworkLiveRoomDetail.fromJson(<String, dynamic>{});

      expect(detail.roomInfo, isNull);
      expect(detail.anchorInfo, isNull);
    });

    test('missing title, cover, live_status and anchor names become null', () {
      final detail = NetworkLiveRoomDetail.fromJson(<String, dynamic>{
        'room_info': <String, dynamic>{'room_id': 21144080},
        'anchor_info': <String, dynamic>{'base_info': <String, dynamic>{}},
      });

      expect(detail.roomInfo?.roomId, equals(21144080));
      expect(detail.roomInfo?.title, isNull);
      expect(detail.roomInfo?.cover, isNull);
      expect(detail.roomInfo?.liveStatus, isNull);
      expect(detail.anchorInfo?.baseInfo?.uname, isNull);
      expect(detail.anchorInfo?.baseInfo?.face, isNull);
    });

    test('a missing room_id still rejects the response', () {
      expect(
        () => NetworkLiveRoomDetail.fromJson(<String, dynamic>{
          'room_info': <String, dynamic>{'title': '预告'},
        }),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });
  });

  group('BiliNetworkSearch.getLiveRoomDetail', () {
    test('sends roomId parameter and parses the response', () async {
      final requests = <http.BaseRequest>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(loadFixture()),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final network = BiliNetworkSearch(client: client);
      addTearDown(network.close);

      final response = await network.getLiveRoomDetail(roomId: 21144080);

      expect(requests, hasLength(1));
      expect(requests.single.method, 'GET');
      expect(
        requests.single.url.toString(),
        startsWith(
          'https://api.live.bilibili.com/xlive/web-room/v1/index/getH5InfoByRoom',
        ),
      );
      expect(requests.single.url.queryParameters, {'room_id': '21144080'});
      expect(response.roomInfo?.roomId, equals(21144080));
      expect(response.roomInfo?.uid, equals(392836434));
    });

    test('maps non-2xx responses to BpiHttpException', () async {
      final network = BiliNetworkSearch(
        client: MockClient(
          (_) async => http.Response(
            '{}',
            500,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      addTearDown(network.close);

      expect(
        network.getLiveRoomDetail(roomId: 21144080),
        throwsA(
          isA<BpiHttpException>().having(
            (error) => error.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });

    test('maps a non-zero Bilibili code to BiliApiException', () async {
      final network = BiliNetworkSearch(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'code': 19002000, 'message': 'room not found'}),
            200,
          ),
        ),
      );
      addTearDown(network.close);

      expect(
        network.getLiveRoomDetail(roomId: 21144080),
        throwsA(
          isA<BiliApiException>()
              .having((error) => error.biliCode, 'biliCode', 19002000)
              .having((error) => error.message, 'message', 'room not found'),
        ),
      );
    });

    test('maps malformed JSON to BpiSerializationException', () async {
      final network = BiliNetworkSearch(
        client: MockClient((_) async => http.Response('invalid-json', 200)),
      );
      addTearDown(network.close);

      expect(
        network.getLiveRoomDetail(roomId: 21144080),
        throwsA(isA<BpiSerializationException>()),
      );
    });
  });
}

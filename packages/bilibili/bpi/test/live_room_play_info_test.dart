import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/live_room_play_info.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('parses real live_room_play_info.json fixture correctly', () {
    final json = loadFixture();
    expect(json['code'], equals(0));
    final data = json['data'] as Map<String, dynamic>;
    final info = NetworkLiveRoomPlayInfo.fromJson(data);

    expect(info.roomId, equals(21144080));
    expect(info.uid, equals(392836434));
    expect(info.liveStatus, equals(1));
    expect(info.playurlInfo, isNotNull);

    final playurl = info.playurlInfo?.playurl;
    expect(playurl, isNotNull);
    expect(playurl?.cid, equals(21144080));
    expect(playurl?.gQnDesc, isNotEmpty);
    expect(
      playurl?.gQnDesc.any((item) => item.qn == 10000 && item.desc == '原画'),
      isTrue,
    );

    expect(playurl?.stream, isNotEmpty);
    final firstStream = playurl?.stream.first;
    expect(firstStream?.protocolName, equals('http_stream'));
    expect(firstStream?.format, isNotEmpty);

    final firstFormat = firstStream?.format.first;
    expect(firstFormat?.formatName, equals('flv'));
    expect(firstFormat?.codec, isNotEmpty);

    final firstCodec = firstFormat?.codec.first;
    expect(firstCodec?.codecName, equals('avc'));
    expect(firstCodec?.baseUrl, contains('.flv'));
    expect(firstCodec?.urlInfo, isNotEmpty);
    expect(firstCodec?.urlInfo.first.host, contains('bilivideo.com'));
  });

  group('missing non-core fields', () {
    test('missing playurl_info leaves playurlInfo null without throwing', () {
      final info = NetworkLiveRoomPlayInfo.fromJson(<String, dynamic>{
        'room_id': 21144080,
      });

      expect(info.roomId, equals(21144080));
      expect(info.playurlInfo, isNull);
    });

    test('missing optional stream codec fields parse gracefully with default empty lists', () {
      final info = NetworkLiveRoomPlayInfo.fromJson(<String, dynamic>{
        'room_id': 21144080,
        'playurl_info': <String, dynamic>{
          'playurl': <String, dynamic>{'cid': 21144080},
        },
      });

      expect(info.roomId, equals(21144080));
      final playurl = info.playurlInfo?.playurl;
      expect(playurl?.gQnDesc, isEmpty);
      expect(playurl?.stream, isEmpty);
    });
  });

  group('BiliNetworkSearch.getLiveRoomPlayInfo', () {
    test('sends roomId and default parameters and parses response', () async {
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

      final response = await network.getLiveRoomPlayInfo(roomId: 21144080);

      expect(requests, hasLength(1));
      expect(requests.single.method, 'GET');
      expect(
        requests.single.url.toString(),
        startsWith(
          'https://api.live.bilibili.com/xlive/web-room/v2/index/getRoomPlayInfo',
        ),
      );
      expect(requests.single.url.queryParameters, {
        'room_id': '21144080',
        'qn': '10000',
        'protocol': '0,1',
        'format': '0,1,2',
        'codec': '0,1',
        'platform': 'web',
        'ptype': '8',
      });
      expect(response.roomId, equals(21144080));
      expect(response.playurlInfo?.playurl?.cid, equals(21144080));
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
        network.getLiveRoomPlayInfo(roomId: 21144080),
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
        network.getLiveRoomPlayInfo(roomId: 21144080),
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
        network.getLiveRoomPlayInfo(roomId: 21144080),
        throwsA(isA<BpiSerializationException>()),
      );
    });
  });
}

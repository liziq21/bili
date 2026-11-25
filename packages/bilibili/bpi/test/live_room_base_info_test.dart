import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/live_room_base_info.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('parses the captured live room base info response', () {
    final response = NetworkLiveRoomBaseInfo.fromJson(loadFixture());

    expect(response.code, 0);
    expect(response.rooms, hasLength(2));

    final room = response.rooms[21144080];
    expect(room, isNotNull);
    expect(room?.uid, 392836434);
    expect(room?.liveStatus, 1);
    expect(room?.title, isNotEmpty);
    expect(room?.uname, isNotEmpty);
  });

  test('drops rooms without a numeric room_id', () {
    final response = NetworkLiveRoomBaseInfo.fromJson({
      'code': 0,
      'message': 'OK',
      'data': {
        'by_room_ids': {
          'bad': {'title': 'no room id'},
          '1': {'room_id': 1, 'title': 'kept'},
        },
      },
    });

    expect(response.rooms, hasLength(1));
    expect(response.rooms[1]?.title, 'kept');
  });

  group('BiliNetworkSearch.getLiveRoomBaseInfo', () {
    test('sends repeated room_ids parameters', () async {
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

      final response = await network.getLiveRoomBaseInfo(
        roomIds: [21144080, 21452505],
      );

      expect(requests, hasLength(1));
      expect(
        requests.single.url.path,
        '/xlive/web-room/v1/index/getRoomBaseInfo',
      );
      expect(requests.single.url.queryParametersAll['room_ids'], [
        '21144080',
        '21452505',
      ]);
      expect(requests.single.url.queryParameters['req_biz'], 'web');
      expect(response.rooms, hasLength(2));
    });

    test('maps a non-zero Bilibili code to BiliApiException', () async {
      final network = BiliNetworkSearch(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'code': -400, 'message': 'invalid room id'}),
            200,
          ),
        ),
      );
      addTearDown(network.close);

      expect(
        network.getLiveRoomBaseInfo(roomIds: [1]),
        throwsA(isA<BiliApiException>()),
      );
    });
  });
}

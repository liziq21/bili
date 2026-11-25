import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/live_recommended_rooms.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('parses the captured recommended live rooms response', () {
    final response = NetworkLiveRecommendedRooms.fromJson(loadFixture());

    expect(response.code, 0);
    expect(response.rooms, hasLength(30));

    final room = response.rooms.first;
    expect(room.roomId, 1883358196);
    expect(room.uid, 3546687211572101);
    expect(room.title, isNotEmpty);
    expect(room.uname, isNotEmpty);
  });

  test('drops recommended rooms without a numeric roomid', () {
    final response = NetworkLiveRecommendedRooms.fromJson({
      'code': 0,
      'message': 'ok',
      'data': [
        {'title': 'no room id'},
        {'roomid': 1, 'title': 'kept'},
      ],
    });

    expect(response.rooms, hasLength(1));
    expect(response.rooms.single.roomId, 1);
  });

  group('BiliNetworkSearch.getRecommendedLiveRooms', () {
    test('sends the page size and platform', () async {
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

      final response = await network.getRecommendedLiveRooms();

      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/room/v1/room/get_user_recommend');
      expect(requests.single.url.queryParameters, {
        'page_size': '30',
        'platform': 'web',
      });
      expect(response.rooms, hasLength(30));
    });

    test('maps a non-zero Bilibili code to BiliApiException', () async {
      final network = BiliNetworkSearch(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'code': -400, 'message': 'bad request'}),
            200,
          ),
        ),
      );
      addTearDown(network.close);

      expect(
        network.getRecommendedLiveRooms(),
        throwsA(isA<BiliApiException>()),
      );
    });
  });
}

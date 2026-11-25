import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/live_status_by_uids.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('parses the captured live status response', () {
    final response = NetworkLiveStatusByUids.fromJson(loadFixture());

    expect(response.code, 0);
    expect(response.statuses, hasLength(2));

    final status = response.statuses[3546687211572101];
    expect(status, isNotNull);
    expect(status?.roomId, 1883358196);
    expect(status?.liveStatus, 1);
    expect(status?.title, isNotEmpty);
    expect(status?.uname, isNotEmpty);
  });

  test('drops statuses without a numeric uid', () {
    final response = NetworkLiveStatusByUids.fromJson({
      'code': 0,
      'message': 'success',
      'data': {
        'bad': {'title': 'no uid'},
        '1': {'uid': 1, 'room_id': 2},
      },
    });

    expect(response.statuses, hasLength(1));
    expect(response.statuses[1]?.roomId, 2);
  });

  group('BiliNetworkSearch.getLiveStatusByUids', () {
    test('sends repeated uids[] parameters', () async {
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

      final response = await network.getLiveStatusByUids(
        uids: [8739477, 3546687211572101],
      );

      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/room/v1/Room/get_status_info_by_uids');
      expect(requests.single.url.queryParametersAll['uids[]'], [
        '8739477',
        '3546687211572101',
      ]);
      expect(response.statuses, hasLength(2));
    });

    test('maps a non-zero Bilibili code to BiliApiException', () async {
      final network = BiliNetworkSearch(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'code': 65530, 'message': 'route_exception'}),
            200,
          ),
        ),
      );
      addTearDown(network.close);

      expect(
        network.getLiveStatusByUids(uids: [1]),
        throwsA(
          isA<BiliApiException>().having(
            (error) => error.biliCode,
            'biliCode',
            65530,
          ),
        ),
      );
    });
  });
}

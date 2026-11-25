import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/video_parts.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('parses the captured video parts response', () {
    final response = NetworkBiliVideoParts.fromJson(loadFixture());

    expect(response.code, 0);
    expect(response.message, 'OK');
    expect(response.parts, hasLength(1));

    final part = response.parts.single;
    expect(part.cid, 137646676);
    expect(part.page, 1);
    expect(part.part, '教科书上的道具操作都有');
    expect(part.duration, 105);
    expect(part.width, 1280);
    expect(part.height, 720);
  });

  test('drops parts without a cid and tolerates missing dimensions', () {
    final response = NetworkBiliVideoParts.fromJson({
      'code': 0,
      'message': 'OK',
      'ttl': 1,
      'data': [
        {'page': 1, 'part': 'no cid'},
        {'cid': 42, 'page': 2, 'part': 'ok'},
      ],
    });

    expect(response.parts, hasLength(1));
    expect(response.parts.single.cid, 42);
    expect(response.parts.single.width, isNull);
  });

  group('BiliNetworkSearch.getVideoParts', () {
    test('sends bvid and parses the response', () async {
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

      final response = await network.getVideoParts(bvid: 'BV1GJ411x7vy');

      expect(requests, hasLength(1));
      expect(requests.single.method, 'GET');
      expect(requests.single.url.path, '/x/player/pagelist');
      expect(requests.single.url.queryParameters, {'bvid': 'BV1GJ411x7vy'});
      expect(response.parts.single.cid, 137646676);
    });

    test('maps a non-zero Bilibili code to BiliApiException', () async {
      final network = BiliNetworkSearch(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'code': -400, 'message': 'request failed'}),
            200,
          ),
        ),
      );
      addTearDown(network.close);

      expect(
        network.getVideoParts(bvid: 'BV1GJ411x7vy'),
        throwsA(
          isA<BiliApiException>()
              .having((error) => error.biliCode, 'biliCode', -400)
              .having((error) => error.message, 'message', 'request failed'),
        ),
      );
    });

    test('maps a malformed envelope to BpiSerializationException', () async {
      final network = BiliNetworkSearch(
        client: MockClient(
          (_) async => http.Response(jsonEncode({'code': 0}), 200),
        ),
      );
      addTearDown(network.close);

      expect(
        network.getVideoParts(bvid: 'BV1GJ411x7vy'),
        throwsA(isA<BpiSerializationException>()),
      );
    });
  });
}

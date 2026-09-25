import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/popular.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('parses the captured popular response', () {
    final response = NetworkBiliPopularResponse.fromJson(loadFixture());

    expect(response.code, 0);
    expect(response.message, 'OK');
    expect(response.ttl, 1);
    expect(response.data.list, hasLength(20));
    expect(response.data.noMore, isFalse);

    final video = response.data.list.first;
    expect(video.aid, 117319699272083);
    expect(video.bvid, 'BV1Deht6rEpZ');
    expect(video.title, isNotEmpty);
    expect(video.owner?.mid, isNotNull);
    expect(video.stat?.view, isNotNull);
  });

  test('drops items without aid or bvid and tolerates optional fields', () {
    final response = NetworkBiliPopularResponse.fromJson({
      'code': 0,
      'message': 'OK',
      'ttl': 1,
      'data': {
        'no_more': true,
        'list': [
          {'bvid': 'BVmissingAid'},
          {'aid': 1},
          {'aid': 2, 'bvid': 'BVok', 'owner': {}, 'stat': {}},
        ],
      },
    });

    expect(response.data.list, hasLength(1));
    expect(response.data.list.single.bvid, 'BVok');
    expect(response.data.list.single.owner, isNull);
    expect(response.data.list.single.stat, isNull);
    expect(response.data.noMore, isTrue);
  });

  group('BiliNetworkSearch.getPopular', () {
    test('sends pn and ps and parses the response', () async {
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

      final response = await network.getPopular();

      expect(requests, hasLength(1));
      expect(requests.single.method, 'GET');
      expect(requests.single.url.path, '/x/web-interface/popular');
      expect(requests.single.url.queryParameters, {'pn': '1', 'ps': '20'});
      expect(response.data.list, hasLength(20));
    });

    test('maps non-2xx responses to BpiHttpException', () async {
      final network = BiliNetworkSearch(
        client: MockClient(
          (_) async => http.Response(
            '{}',
            503,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      addTearDown(network.close);

      expect(
        network.getPopular(),
        throwsA(
          isA<BpiHttpException>().having(
            (error) => error.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
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
        network.getPopular(),
        throwsA(
          isA<BiliApiException>()
              .having((error) => error.biliCode, 'biliCode', -400)
              .having((error) => error.message, 'message', 'request failed'),
        ),
      );
    });

    test('maps malformed JSON to BpiSerializationException', () async {
      final network = BiliNetworkSearch(
        client: MockClient((_) async => http.Response('not-json', 200)),
      );
      addTearDown(network.close);

      expect(network.getPopular(), throwsA(isA<BpiSerializationException>()));
    });

    test('maps a client failure to BpiNetworkException', () async {
      final network = BiliNetworkSearch(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      addTearDown(network.close);

      expect(
        network.getPopular(),
        throwsA(
          isA<BpiNetworkException>().having(
            (error) => error.cause,
            'cause',
            isA<http.ClientException>(),
          ),
        ),
      );
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/ranking.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('parses the captured ranking response', () {
    final response = NetworkBiliRankingResponse.fromJson(loadFixture());

    expect(response.code, 0);
    expect(response.message, 'OK');
    expect(response.ttl, 1);
    expect(response.data.list, hasLength(100));
    expect(response.data.note, isNotEmpty);

    final video = response.data.list.first;
    expect(video.aid, 117313961463398);
    expect(video.bvid, 'BV1YDhJ6ZEL6');
    expect(video.title, isNotEmpty);
    expect(video.owner?.mid, isNotNull);
    expect(video.stat?.view, isNotNull);
    expect(video.stat?.hisRank, 1);
  });

  test('drops items without aid or bvid and tolerates optional fields', () {
    final response = NetworkBiliRankingResponse.fromJson({
      'code': 0,
      'message': 'OK',
      'ttl': 1,
      'data': {
        'note': 'ranking',
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
    expect(response.data.note, 'ranking');
  });

  test('drops items with numeric or malformed bvid values', () {
    final response = NetworkBiliRankingResponse.fromJson({
      'code': 0,
      'message': 'OK',
      'ttl': 1,
      'data': {
        'note': 'ranking',
        'list': [
          {'aid': 1, 'bvid': 123},
          {'aid': 2, 'bvid': ''},
          {'aid': 3, 'bvid': 'BVgood', 'owner': {}, 'stat': {}},
        ],
      },
    });

    expect(response.data.list, hasLength(1));
    expect(response.data.list.single.bvid, 'BVgood');
  });

  group('BiliNetworkSearch.getRanking', () {
    test('sends rid and type and parses the response', () async {
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

      final response = await network.getRanking();

      expect(requests, hasLength(1));
      expect(requests.single.method, 'GET');
      expect(requests.single.url.path, '/x/web-interface/ranking/v2');
      expect(requests.single.url.queryParameters, {'rid': '0', 'type': 'all'});
      expect(response.data.list, hasLength(100));
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
        network.getRanking(),
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
        network.getRanking(),
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

      expect(network.getRanking(), throwsA(isA<BpiSerializationException>()));
    });

    test('maps a client failure to BpiNetworkException', () async {
      final network = BiliNetworkSearch(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      addTearDown(network.close);

      expect(
        network.getRanking(),
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

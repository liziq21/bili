import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/bangumi_season.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('parses real bangumi_season.json fixture correctly', () {
    final json = loadFixture();
    expect(json['code'], equals(0));
    final result = json['result'] as Map<String, dynamic>;
    final season = NetworkBangumiSeasonData.fromJson(result);

    expect(season.seasonId, equals(28800));
    expect(season.title, isNotNull);
    expect(season.episodes, isNotNull);
    expect(season.episodes, isNotEmpty);

    final firstEp = season.episodes!.first;
    expect(firstEp.epId, equals(289148));
    expect(firstEp.aid, equals(70871306));
    expect(firstEp.bvid, equals('BV1kE411o7q2'));
    expect(firstEp.cid, equals(122951587));
    expect(firstEp.title, equals('正片'));
  });

  group('BiliNetworkSearch.getBangumiSeason', () {
    test('sends seasonId parameter and parses the response', () async {
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

      final response = await network.getBangumiSeason(seasonId: 28800);

      expect(requests, hasLength(1));
      expect(requests.single.method, 'GET');
      expect(
        requests.single.url.toString(),
        startsWith('https://api.bilibili.com/pgc/view/web/season'),
      );
      expect(requests.single.url.queryParameters, {'season_id': '28800'});
      expect(response.seasonId, equals(28800));
      expect(response.episodes, isNotEmpty);
    });

    test('sends epId parameter and parses the response', () async {
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

      final response = await network.getBangumiSeason(epId: 331408);

      expect(requests, hasLength(1));
      expect(requests.single.method, 'GET');
      expect(
        requests.single.url.toString(),
        startsWith('https://api.bilibili.com/pgc/view/web/season'),
      );
      expect(requests.single.url.queryParameters, {'ep_id': '331408'});
      expect(response.seasonId, equals(28800));
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
        network.getBangumiSeason(seasonId: 28800),
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
            jsonEncode({'code': -404, 'message': '啥都木有'}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      addTearDown(network.close);

      expect(
        network.getBangumiSeason(seasonId: 28800),
        throwsA(
          isA<BiliApiException>()
              .having((error) => error.biliCode, 'biliCode', -404)
              .having((error) => error.message, 'message', '啥都木有'),
        ),
      );
    });

    test('maps malformed JSON to BpiSerializationException', () async {
      final network = BiliNetworkSearch(
        client: MockClient((_) async => http.Response('invalid-json', 200)),
      );
      addTearDown(network.close);

      expect(
        network.getBangumiSeason(seasonId: 28800),
        throwsA(isA<BpiSerializationException>()),
      );
    });

    test('maps invalid UTF-8 bytes to BpiSerializationException', () async {
      final network = BiliNetworkSearch(
        client: MockClient(
          (_) async => http.Response.bytes(
            <int>[0x7B, 0xFF, 0x7D],
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      addTearDown(network.close);

      expect(
        network.getBangumiSeason(seasonId: 28800),
        throwsA(isA<BpiSerializationException>()),
      );
    });
  });
}

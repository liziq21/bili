import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/bangumi_play_url.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('parses real bangumi_play_url.json fixture correctly', () {
    final json = loadFixture();
    expect(json['code'], equals(0));
    final result = json['result'] as Map<String, dynamic>;
    final playUrl = NetworkPlayUrl.fromJson(result);

    expect(playUrl.quality, equals(32));
    expect(playUrl.format, equals('mp4'));
    expect(playUrl.durl, isNotNull);
    expect(playUrl.durl, isNotEmpty);

    final firstDurl = playUrl.durl!.first;
    expect(firstDurl.url, isNotNull);
    expect(firstDurl.url, isNotEmpty);
    expect(firstDurl.playUrls, isNotEmpty);
    expect(firstDurl.playUrls.first, equals(firstDurl.url));
  });

  group('BiliNetworkSearch.getBangumiPlayUrl', () {
    test(
      'sends epId, cid, qn, fnval, fourk parameters and parses the response',
      () async {
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

        final response = await network.getBangumiPlayUrl(
          epId: 326233,
          qn: 80,
          fnval: 4048,
          fourk: 1,
        );

        expect(requests, hasLength(1));
        expect(requests.single.method, 'GET');
        expect(
          requests.single.url.toString(),
          startsWith('https://api.bilibili.com/pgc/player/web/playurl'),
        );
        expect(requests.single.url.queryParameters, {
          'ep_id': '326233',
          'qn': '80',
          'fnval': '4048',
          'fourk': '1',
        });
        expect(response.quality, equals(32));
        expect(response.durl, isNotEmpty);
      },
    );

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
        network.getBangumiPlayUrl(epId: 326233),
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
        network.getBangumiPlayUrl(epId: 326233),
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
        network.getBangumiPlayUrl(epId: 326233),
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
        network.getBangumiPlayUrl(epId: 326233),
        throwsA(isA<BpiSerializationException>()),
      );
    });
  });
}

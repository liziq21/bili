import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/player_v2.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('parses real player_v2.json fixture correctly', () {
    final json = loadFixture();
    expect(json['code'], equals(0));
    final data = json['data'] as Map<String, dynamic>;
    final playerInfo = NetworkBiliPlayerInfo.fromJson(data);

    expect(playerInfo.aid, equals(80431228));
    expect(playerInfo.bvid, equals('BV1GJ411x7vy'));
    expect(playerInfo.cid, equals(137646676));
    expect(playerInfo.isOwner, isFalse);
    expect(playerInfo.subtitle, isNotNull);
    expect(playerInfo.subtitle?.allowSubmit, isFalse);
  });

  group('NetworkBiliSubtitleItem missing lan_doc', () {
    Map<String, dynamic> playerDataWithSubtitle(
      List<Map<String, dynamic>> subs,
    ) => (loadFixture()['data'] as Map<String, dynamic>)
      ..['subtitle'] = <String, dynamic>{
        'allow_submit': false,
        'lan': '',
        'lan_doc': '',
        'subtitles': subs,
        'subtitle_position': null,
        'font_size_type': 0,
      };

    test('parses when lan_doc is absent', () {
      final data = playerDataWithSubtitle([
        <String, dynamic>{
          'id': 1,
          'lan': 'zh-CN',
          'subtitle_url': 'https://example.com/a.vtt',
        },
      ]);

      final playerInfo = NetworkBiliPlayerInfo.fromJson(data);

      expect(playerInfo.subtitle?.subtitles, hasLength(1));
      expect(playerInfo.subtitle?.subtitles?.single.lanDoc, isNull);
      // The rest of the response survives the missing non-core field.
      expect(playerInfo.subtitle?.subtitles?.single.lan, equals('zh-CN'));
      expect(playerInfo.bvid, equals('BV1GJ411x7vy'));
    });

    test('parses when lan_doc is null', () {
      final data = playerDataWithSubtitle([
        <String, dynamic>{
          'id': 2,
          'lan': 'zh-CN',
          'lan_doc': null,
          'subtitle_url': 'https://example.com/b.vtt',
        },
      ]);

      final playerInfo = NetworkBiliPlayerInfo.fromJson(data);

      expect(playerInfo.subtitle?.subtitles?.single.lanDoc, isNull);
    });

    test('still parses when lan_doc is present', () {
      final data = playerDataWithSubtitle([
        <String, dynamic>{
          'id': 3,
          'lan': 'zh-CN',
          'lan_doc': '中文（中国）',
          'subtitle_url': 'https://example.com/c.vtt',
        },
      ]);

      final playerInfo = NetworkBiliPlayerInfo.fromJson(data);

      expect(playerInfo.subtitle?.subtitles?.single.lanDoc, equals('中文（中国）'));
    });

    test('coerces a non-string lan_doc to null', () {
      for (final retyped in <Object>[
        42,
        true,
        <String>['中文'],
        <String, String>{},
      ]) {
        final data = playerDataWithSubtitle([
          <String, dynamic>{
            'id': 3,
            'lan': 'zh-CN',
            'lan_doc': retyped,
            'subtitle_url': 'https://example.com/c.vtt',
          },
        ]);

        final playerInfo = NetworkBiliPlayerInfo.fromJson(data);

        expect(
          playerInfo.subtitle?.subtitles?.single.lanDoc,
          isNull,
          reason:
              'lan_doc of type ${retyped.runtimeType} must not reach the model',
        );
        expect(playerInfo.subtitle?.subtitles?.single.lan, equals('zh-CN'));
      }
    });
  });

  group('BiliNetworkSearch.getPlayerInfo', () {
    test('sends bvid and cid parameters and parses the response', () async {
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

      final response = await network.getPlayerInfo(
        bvid: 'BV1GJ411x7vy',
        cid: 137646676,
      );

      expect(requests, hasLength(1));
      expect(requests.single.method, 'GET');
      expect(requests.single.url.path, '/x/player/v2');
      expect(requests.single.url.queryParameters, {
        'bvid': 'BV1GJ411x7vy',
        'cid': '137646676',
      });
      expect(response.aid, equals(80431228));
      expect(response.bvid, equals('BV1GJ411x7vy'));
      expect(response.cid, equals(137646676));
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
        network.getPlayerInfo(bvid: 'BV1GJ411x7vy', cid: 137646676),
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
            jsonEncode({'code': -404, 'message': 'video not found'}),
            200,
          ),
        ),
      );
      addTearDown(network.close);

      expect(
        network.getPlayerInfo(bvid: 'BV1GJ411x7vy', cid: 137646676),
        throwsA(
          isA<BiliApiException>()
              .having((error) => error.biliCode, 'biliCode', -404)
              .having((error) => error.message, 'message', 'video not found'),
        ),
      );
    });

    test('maps malformed JSON to BpiSerializationException', () async {
      final network = BiliNetworkSearch(
        client: MockClient((_) async => http.Response('invalid-json', 200)),
      );
      addTearDown(network.close);

      expect(
        network.getPlayerInfo(bvid: 'BV1GJ411x7vy', cid: 137646676),
        throwsA(isA<BpiSerializationException>()),
      );
    });
  });
}

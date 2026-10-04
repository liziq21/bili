import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/user_card.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('parses real user_card.json fixture correctly', () {
    final json = loadFixture();
    expect(json['code'], equals(0));
    final data = json['data'] as Map<String, dynamic>;
    final userCard = NetworkBiliUserCardData.fromJson(data);

    expect(userCard.card.mid, equals('2'));
    expect(userCard.card.name, equals('碧诗'));
    expect(userCard.card.sex, equals('男'));
    expect(userCard.card.fans, equals(1430413));
    expect(userCard.card.attention, equals(430));
    expect(userCard.card.levelInfo?.currentLevel, equals(6));
    expect(userCard.card.officialVerify?.desc, equals('bilibili创始人（站长）'));
    expect(userCard.follower, equals(1430413));
  });

  test('accepts optional counts returned as numeric strings', () {
    final data = {
      'card': {
        'mid': 2,
        'name': '碧诗',
        'fans': '1430413',
        'attention': '430',
        'level_info': {'current_level': '6', 'current_exp': '12000'},
      },
      'archive_count': '9527',
      'article_count': 214,
      'follower': null,
    };

    final userCard = NetworkBiliUserCardData.fromJson(data);

    expect(userCard.card.fans, equals(1430413));
    expect(userCard.card.attention, equals(430));
    expect(userCard.card.levelInfo?.currentLevel, equals(6));
    expect(userCard.archiveCount, equals(9527));
    expect(userCard.articleCount, equals(214));
    expect(userCard.follower, isNull);
  });

  test('drops optional counts that are neither number nor numeric string', () {
    final data = {
      'card': {'mid': '2', 'name': '碧诗', 'fans': 'N/A'},
      'archive_count': <String>[],
    };

    final userCard = NetworkBiliUserCardData.fromJson(data);

    expect(userCard.card.fans, isNull);
    expect(userCard.archiveCount, isNull);
  });

  group('BiliNetworkSearch.getUserCard', () {
    test('sends mid parameter and parses the response', () async {
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

      final response = await network.getUserCard(mid: 2);

      expect(requests, hasLength(1));
      expect(requests.single.method, 'GET');
      expect(
        requests.single.url.toString(),
        startsWith('https://api.bilibili.com/x/web-interface/card'),
      );
      expect(requests.single.url.queryParameters, {'mid': '2'});
      expect(response.card.mid, equals('2'));
      expect(response.card.name, equals('碧诗'));
      expect(response.follower, equals(1430413));
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
        network.getUserCard(mid: 2),
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
            jsonEncode({'code': -400, 'message': '请求错误'}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      addTearDown(network.close);

      expect(
        network.getUserCard(mid: 2),
        throwsA(
          isA<BiliApiException>()
              .having((error) => error.biliCode, 'biliCode', -400)
              .having((error) => error.message, 'message', '请求错误'),
        ),
      );
    });

    test('maps malformed JSON to BpiSerializationException', () async {
      final network = BiliNetworkSearch(
        client: MockClient((_) async => http.Response('invalid-json', 200)),
      );
      addTearDown(network.close);

      expect(
        network.getUserCard(mid: 2),
        throwsA(isA<BpiSerializationException>()),
      );
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/user_articles.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('parses real user_articles.json fixture correctly', () {
    final json = loadFixture();
    expect(json['code'], equals(0));
    final data = json['data'] as Map<String, dynamic>;
    final articlesData = NetworkBiliUserArticlesData.fromJson(data);

    expect(articlesData.pn, equals(1));
    expect(articlesData.ps, equals(30));
    expect(articlesData.count, equals(302));
    expect(articlesData.articles, isNotNull);
    expect(articlesData.articles, isNotEmpty);

    final first = articlesData.articles!.first;
    expect(first.id, equals(53109096));
    expect(first.title, equals('剧情活动预告'));
    expect(first.summary, contains('Demon/Snow 起死回生的冥府旅情'));
    expect(first.publishTime, equals(1790050500));
    expect(first.imageUrls, isNotEmpty);
    expect(first.stats?.view, isNotNull);
    expect(first.stats?.like, isNotNull);
  });

  test('tolerates missing optional fields or null articles list', () {
    final data = {'pn': '1', 'ps': '30', 'count': '0', 'articles': null};

    final articlesData = NetworkBiliUserArticlesData.fromJson(data);

    expect(articlesData.pn, equals(1));
    expect(articlesData.ps, equals(30));
    expect(articlesData.count, equals(0));
    expect(articlesData.articles, isNull);
  });

  test(
    'skips articles missing the core id instead of failing the whole page',
    () {
      final data = {
        'pn': '1',
        'ps': '30',
        'count': '3',
        'articles': [
          {'id': 53109096, 'title': '正常文章'},
          // 缺核心标识 id 的坏条目：必须被跳过，不能让整页解析失败。
          {'title': '无 id 的坏条目'},
          {'id': 53109097, 'title': '另一篇正常文章'},
        ],
      };

      final articlesData = NetworkBiliUserArticlesData.fromJson(data);

      expect(articlesData.articles, hasLength(2));
      expect(articlesData.articles!.map((a) => a.id), [53109096, 53109097]);
    },
  );

  test('tolerates an article missing the non-core title', () {
    final data = {
      'pn': '1',
      'ps': '30',
      'count': '1',
      'articles': [
        // id 是核心标识必须存在；title 缺失读为 null，不丢弃该条目。
        {'id': 53109096},
      ],
    };

    final articlesData = NetworkBiliUserArticlesData.fromJson(data);

    expect(articlesData.articles, hasLength(1));
    expect(articlesData.articles!.single.id, equals(53109096));
    expect(articlesData.articles!.single.title, isNull);
  });

  group('BiliNetworkSearch.getUserArticles', () {
    test(
      'sends mid, page, and pageSize parameters and parses the response',
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

        final response = await network.getUserArticles(
          mid: 353840826,
          page: 1,
          pageSize: 30,
        );

        expect(requests, hasLength(1));
        expect(requests.single.method, 'GET');
        expect(
          requests.single.url.toString(),
          startsWith('https://api.bilibili.com/x/space/article'),
        );
        expect(requests.single.url.queryParameters, {
          'mid': '353840826',
          'pn': '1',
          'ps': '30',
        });
        expect(response.count, equals(302));
        expect(response.articles, isNotEmpty);
        expect(response.articles!.first.id, equals(53109096));
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
        network.getUserArticles(mid: 353840826),
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
        network.getUserArticles(mid: 353840826),
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
        network.getUserArticles(mid: 353840826),
        throwsA(isA<BpiSerializationException>()),
      );
    });

    test('maps network failures to BpiNetworkException', () async {
      final network = BiliNetworkSearch(
        client: MockClient(
          (_) async => throw SocketException('No route to host'),
        ),
      );
      addTearDown(network.close);

      expect(
        network.getUserArticles(mid: 353840826),
        throwsA(isA<BpiNetworkException>()),
      );
    });
  });
}

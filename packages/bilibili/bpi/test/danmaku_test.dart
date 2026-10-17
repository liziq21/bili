import 'dart:io';
import 'dart:convert';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  String loadFixture() {
    final file = File('testing/danmaku.xml');
    expect(file.existsSync(), isTrue);
    return file.readAsStringSync();
  }

  test('parses the real danmaku XML fixture', () {
    final document = NetworkBiliDanmakuDocument.fromXml(loadFixture());

    expect(document.chatServer, equals('chat.bilibili.com'));
    expect(document.chatId, equals(42164617674));
    expect(document.comments, isNotEmpty);
    expect(document.comments.every((item) => item.content.isNotEmpty), isTrue);
    expect(document.comments.every((item) => item.startSeconds >= 0), isTrue);
  });

  test('skips malformed comments while keeping valid comments', () {
    final document = NetworkBiliDanmakuDocument.fromXml('''
      <i>
        <chatid>7</chatid>
        <d p="1.5,1,25,16777215,1,0,hash,9">valid &amp; visible</d>
        <d p="not-valid">discarded</d>
      </i>
    ''');

    expect(document.comments, hasLength(1));
    expect(document.comments.single.content, equals('valid & visible'));
    expect(document.comments.single.rowId, equals(9));
  });

  group('BiliNetworkSearch.getDanmaku', () {
    test('sends the cid in the public XML endpoint request', () async {
      final requests = <http.BaseRequest>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response.bytes(
          utf8.encode(loadFixture()),
          200,
          headers: const {'content-type': 'application/xml'},
        );
      });
      final network = BiliNetworkSearch(client: client);
      addTearDown(network.close);

      final document = await network.getDanmaku(cid: 42164617674);

      expect(requests, hasLength(1));
      expect(requests.single.method, 'GET');
      expect(requests.single.url.host, 'comment.bilibili.com');
      expect(requests.single.url.path, '/42164617674.xml');
      expect(requests.single.url.query, isEmpty);
      expect(requests.single.headers['referer'], 'https://www.bilibili.com/');
      expect(document.comments, isNotEmpty);
    });

    test('maps non-2xx responses to BpiHttpException', () async {
      final network = BiliNetworkSearch(
        client: MockClient((_) async => http.Response('denied', 403)),
      );
      addTearDown(network.close);

      expect(
        network.getDanmaku(cid: 42164617674),
        throwsA(
          isA<BpiHttpException>().having(
            (error) => error.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
    });

    test('maps malformed XML to BpiSerializationException', () async {
      final network = BiliNetworkSearch(
        client: MockClient((_) async => http.Response('<broken>', 200)),
      );
      addTearDown(network.close);

      expect(
        network.getDanmaku(cid: 42164617674),
        throwsA(isA<BpiSerializationException>()),
      );
    });

    test('maps transport errors to BpiNetworkException', () async {
      final network = BiliNetworkSearch(
        client: MockClient((_) async => throw const SocketException('offline')),
      );
      addTearDown(network.close);

      expect(
        network.getDanmaku(cid: 42164617674),
        throwsA(isA<BpiNetworkException>()),
      );
    });
  });
}

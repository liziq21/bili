import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/video_snapshot.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('parses the captured video snapshot response', () {
    final response = NetworkBiliVideoSnapshot.fromJson(loadFixture());

    expect(response.code, 0);
    expect(response.message, 'OK');
    expect(response.imgXLen, 10);
    expect(response.imgYLen, 10);
    expect(response.imgXSize, 160);
    expect(response.imgYSize, 90);
    expect(response.images, hasLength(1));
    expect(response.images.single, contains('videoshot'));
    expect(response.index, hasLength(22));
  });

  test('tolerates a snapshot without image or index lists', () {
    final response = NetworkBiliVideoSnapshot.fromJson({
      'code': 0,
      'message': 'OK',
      'data': {'pvdata': 'https://example.invalid/storyboard.bin'},
    });

    expect(response.images, isEmpty);
    expect(response.index, isEmpty);
    expect(response.pvdata, 'https://example.invalid/storyboard.bin');
  });

  group('BiliNetworkSearch.getVideoSnapshot', () {
    test('sends bvid and the default index and parses the response', () async {
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

      final response = await network.getVideoSnapshot(bvid: 'BV1GJ411x7vy');

      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/x/player/videoshot');
      expect(requests.single.url.queryParameters, {
        'bvid': 'BV1GJ411x7vy',
        'index': '1',
      });
      expect(response.images, isNotEmpty);
    });

    test('forwards a non-default snapshot index', () async {
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

      await network.getVideoSnapshot(bvid: 'BV1GJ411x7vy', index: 3);

      expect(requests.single.url.queryParameters['index'], '3');
    });

    test('maps a non-zero Bilibili code to BiliApiException', () async {
      final network = BiliNetworkSearch(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'code': -404, 'message': 'not found'}),
            200,
          ),
        ),
      );
      addTearDown(network.close);

      expect(
        network.getVideoSnapshot(bvid: 'BV1GJ411x7vy'),
        throwsA(
          isA<BiliApiException>().having(
            (error) => error.biliCode,
            'biliCode',
            -404,
          ),
        ),
      );
    });
  });
}

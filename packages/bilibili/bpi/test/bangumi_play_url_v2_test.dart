import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/bangumi_play_url_v2.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('parses the captured bangumi play url v2 response', () {
    final json = loadFixture();
    final response = NetworkBangumiPlayUrlV2.fromJson(
      json['result'] as Map<String, dynamic>,
    );

    expect(response.videoInfo.quality, 32);
    expect(response.videoInfo.durl, isNotEmpty);
    expect(response.episodeInfo?.epId, 326233);
    expect(response.episodeInfo?.cid, 179393043);
    expect(response.episodeInfo?.bvid, 'BV12U4y1M7AS');
  });

  test('tolerates a result without episode info', () {
    final response = NetworkBangumiPlayUrlV2.fromJson({
      'video_info': {
        'quality': 16,
        'durl': [
          {'order': 1, 'url': 'https://example.invalid/stream.mp4'},
        ],
      },
    });

    expect(response.videoInfo.quality, 16);
    expect(response.episodeInfo, isNull);
  });

  group('BiliNetworkSearch.getBangumiPlayUrlV2', () {
    test('sends ep_id and the default quality parameters', () async {
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

      final response = await network.getBangumiPlayUrlV2(epId: 326233);

      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/pgc/player/web/v2/playurl');
      expect(requests.single.url.queryParameters, {
        'ep_id': '326233',
        'qn': '80',
        'fnval': '4048',
        'fourk': '1',
      });
      expect(response.episodeInfo?.epId, 326233);
    });

    test('maps a non-zero Bilibili code to BiliApiException', () async {
      final network = BiliNetworkSearch(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'code': -10403, 'message': 'region restricted'}),
            200,
          ),
        ),
      );
      addTearDown(network.close);

      expect(
        network.getBangumiPlayUrlV2(epId: 326233),
        throwsA(
          isA<BiliApiException>().having(
            (error) => error.biliCode,
            'biliCode',
            -10403,
          ),
        ),
      );
    });
  });
}

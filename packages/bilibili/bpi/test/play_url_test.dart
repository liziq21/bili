import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/play_url.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  group('play_url fixture', () {
    test('parses the anonymous 1080P DASH ladder', () {
      final json = loadFixture();
      expect(json['code'], equals(0));

      final playUrl = NetworkPlayUrl.fromJson(
        json['data'] as Map<String, dynamic>,
      );
      final heights = playUrl.dash?.video
          ?.map((stream) => stream.height)
          .whereType<int>()
          .toSet();

      expect(heights, containsAll(<int>[360, 480, 720, 1080]));
      expect(playUrl.dash?.audio, isNotEmpty);
    });
  });

  group('BiliNetworkSearch.getPlayUrl', () {
    test(
      'sends anonymous HD fingerprint parameters with a WBI signature',
      () async {
        final requests = <http.BaseRequest>[];
        final client = MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/x/web-interface/nav') {
            return http.Response(
              jsonEncode(_navResponse()),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode(loadFixture()),
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        final network = BiliNetworkSearch(client: client);
        addTearDown(network.close);

        final response = await network.getPlayUrl(
          bvid: 'BV1Deht6rEpZ',
          cid: 42164617674,
        );

        expect(response.dash, isNotNull);
        expect(requests, hasLength(2));

        final playRequest = requests.last;
        expect(playRequest.method, 'GET');
        expect(playRequest.url.path, '/x/player/wbi/playurl');

        final query = playRequest.url.queryParameters;
        expect(query['bvid'], equals('BV1Deht6rEpZ'));
        expect(query['cid'], equals('42164617674'));
        expect(query['qn'], equals('80'));
        expect(query['fnver'], equals('0'));
        expect(query['fnval'], equals('4048'));
        expect(query['fourk'], equals('1'));
        expect(query['try_look'], equals('1'));
        expect(query['web_location'], equals('1315873'));
        expect(query['dm_img_list'], equals('[]'));
        expect(query['dm_img_str'], isNotEmpty);
        expect(query['dm_cover_img_str'], isNotEmpty);
        expect(query['dm_img_inter'], contains('"wh"'));
        expect(query['w_rid'], isNotEmpty);
        expect(query['wts'], isNotEmpty);
      },
    );
  });
}

Map<String, dynamic> _navResponse() => <String, dynamic>{
  'code': 0,
  'data': <String, dynamic>{
    'wbi_img': <String, dynamic>{
      'img_url': 'https://i0.hdslb.com/bfs/wbi/${'a' * 32}.png',
      'sub_url': 'https://i0.hdslb.com/bfs/wbi/${'b' * 32}.png',
    },
  },
};

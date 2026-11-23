import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/playlist_list.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  group('playlist_list fixture', () {
    test('parses the live seasons_series_list response', () {
      final json = loadFixture();
      expect(json['code'], equals(0));

      final data = NetworkBiliPlaylistListData.fromJson(
        json['data'] as Map<String, dynamic>,
      );

      final itemsLists = data.itemsLists;
      expect(itemsLists, isNotNull);
      expect(itemsLists?.page?.total, equals(6));
      expect(itemsLists?.seasonsList, hasLength(2));
      expect(itemsLists?.seriesList, hasLength(4));

      final firstSeason = itemsLists?.seasonsList?.first.meta;
      expect(firstSeason?.seasonId, equals(3993361));
      expect(firstSeason?.name, equals('合集·经典领读'));
      expect(firstSeason?.total, equals(22));
      expect(firstSeason?.mid, equals(517327498));
    });
  });

  group('BiliNetworkSearch.getUserPlaylists', () {
    test('sends the web-space path with owner and paging', () async {
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

      final response = await network.getUserPlaylists(
        mid: 517327498,
        pageNum: 1,
        pageSize: 10,
      );

      expect(response.itemsLists?.seasonsList, isNotEmpty);
      expect(requests, hasLength(2));

      final playlistRequest = requests.last;
      expect(playlistRequest.method, 'GET');
      expect(
        playlistRequest.url.path,
        '/x/polymer/web-space/seasons_series_list',
      );

      final query = playlistRequest.url.queryParameters;
      expect(query['mid'], equals('517327498'));
      expect(query['page_num'], equals('1'));
      expect(query['page_size'], equals('10'));
      expect(query['w_rid'], isNotEmpty);
      expect(query['wts'], isNotEmpty);
    });

    test('maps non-2xx responses to BpiHttpException', () async {
      final network = BiliNetworkSearch(
        client: MockClient((request) async {
          if (request.url.path == '/x/web-interface/nav') {
            return http.Response(
              jsonEncode(_navResponse()),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            '{}',
            500,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(network.close);

      expect(
        network.getUserPlaylists(mid: 517327498),
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
        client: MockClient((request) async {
          if (request.url.path == '/x/web-interface/nav') {
            return http.Response(
              jsonEncode(_navResponse()),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({'code': -404, 'message': '啥都木有'}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(network.close);

      expect(
        network.getUserPlaylists(mid: 517327498),
        throwsA(
          isA<BiliApiException>()
              .having((error) => error.biliCode, 'biliCode', -404)
              .having((error) => error.message, 'message', '啥都木有'),
        ),
      );
    });
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

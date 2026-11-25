import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/series_archives.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('parses the captured series archives response', () {
    final response = NetworkBiliSeriesArchives.fromJson(loadFixture());

    expect(response.code, 0);
    expect(response.page?.num, 1);
    expect(response.page?.size, 30);
    expect(response.page?.total, 10);
    expect(response.archives, isNotEmpty);
    expect(response.aids, isNotEmpty);

    final archive = response.archives.first;
    expect(archive.aid, greaterThan(0));
    expect(archive.bvid, isNotEmpty);
    expect(archive.title, isNotEmpty);
    expect(archive.stat?.view, isNotNull);
  });

  test('drops archives without an aid or bvid', () {
    final response = NetworkBiliSeriesArchives.fromJson({
      'code': 0,
      'message': '0',
      'ttl': 1,
      'data': {
        'archives': [
          {'title': 'no identity'},
          {'aid': 1, 'bvid': 'BVok'},
        ],
      },
    });

    expect(response.archives, hasLength(1));
    expect(response.archives.single.bvid, 'BVok');
  });

  group('BiliNetworkSearch.getSeriesArchives', () {
    test('sends the series query and parses the response', () async {
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

      final response = await network.getSeriesArchives(
        mid: 517327498,
        seriesId: 2229877,
      );

      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/x/series/archives');
      expect(requests.single.url.queryParameters, {
        'mid': '517327498',
        'series_id': '2229877',
        'only_normal': 'true',
        'sort': 'desc',
        'pn': '1',
        'ps': '30',
      });
      expect(response.archives, isNotEmpty);
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
        network.getSeriesArchives(mid: 517327498, seriesId: 2229877),
        throwsA(isA<BiliApiException>()),
      );
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/video_tags.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('parses the captured video tags response', () {
    final response = NetworkBiliVideoTags.fromJson(loadFixture());

    expect(response.code, 0);
    expect(response.tags, hasLength(1));
    expect(response.tags.single.tagId, 3172390);
    expect(response.tags.single.tagName, 'QQ飞车手游');
    expect(response.tags.single.tagType, 'old_channel');
  });

  test('drops tags without an id or name', () {
    final response = NetworkBiliVideoTags.fromJson({
      'code': 0,
      'message': 'OK',
      'ttl': 1,
      'data': [
        {'tag_id': 1},
        {'tag_name': 'name only'},
        {'tag_id': 2, 'tag_name': 'kept'},
      ],
    });

    expect(response.tags, hasLength(1));
    expect(response.tags.single.tagName, 'kept');
  });

  group('BiliNetworkSearch.getVideoTags', () {
    test('sends bvid and parses the response', () async {
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

      final response = await network.getVideoTags(bvid: 'BV1GJ411x7vy');

      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/x/web-interface/view/detail/tag');
      expect(requests.single.url.queryParameters, {'bvid': 'BV1GJ411x7vy'});
      expect(response.tags.single.tagId, 3172390);
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
        network.getVideoTags(bvid: 'BV1GJ411x7vy'),
        throwsA(isA<BiliApiException>()),
      );
    });
  });
}

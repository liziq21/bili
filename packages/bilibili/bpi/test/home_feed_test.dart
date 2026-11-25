import 'dart:convert';
import 'dart:io';

import 'package:bpi/bpi.dart';
import 'package:bpi/src/chopper/json_serializable_converter.dart';
import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> loadFixture() {
    final file = File('testing/home_feed.json');
    expect(file.existsSync(), isTrue);
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('parses the captured home feed response', () {
    final response = NetworkBiliHomeFeed.fromJson(loadFixture());

    expect(response.code, 0);
    expect(response.message, 'OK');
    expect(response.items, hasLength(12));

    final item = response.items.first;
    expect(item.goto, 'av');
    expect(item.bvid, 'BV1vtyDzwE7s');
    expect(item.cid, 43857150849);
    expect(item.title, isNotEmpty);
    expect(item.owner?.mid, 401800534);
    expect(item.stat?.view, isNotNull);
  });

  test('drops feed entries without an id or bvid', () {
    final response = NetworkBiliHomeFeed.fromJson({
      'code': 0,
      'message': 'OK',
      'ttl': 1,
      'data': {
        'item': [
          {'goto': 'av', 'title': 'no identity'},
          {'goto': 'av', 'bvid': 'BVok', 'owner': {}, 'stat': {}},
        ],
      },
    });

    expect(response.items, hasLength(1));
    expect(response.items.single.bvid, 'BVok');
    expect(response.items.single.owner, isNull);
    expect(response.items.single.stat, isNull);
  });

  group('BiliNetworkSearch.getHomeFeed', () {
    test('signs the WBI request and sends the feed parameters', () async {
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

      final response = await network.getHomeFeed();

      expect(response.items, hasLength(12));
      expect(requests, hasLength(2));

      final feedRequest = requests.last;
      expect(feedRequest.method, 'GET');
      expect(feedRequest.url.path, '/x/web-interface/wbi/index/top/feed/rcmd');

      final query = feedRequest.url.queryParameters;
      expect(query['fresh_type'], '3');
      expect(query['ps'], '12');
      expect(query['version'], '1');
      expect(query['feed_version'], 'V8');
      expect(query['w_rid'], isNotEmpty);
      expect(query['wts'], isNotEmpty);
    });

    test('maps a non-zero Bilibili code to BiliApiException', () async {
      final network = BiliNetworkSearch(
        client: MockClient((request) async {
          if (request.url.path == '/x/web-interface/nav') {
            return http.Response(jsonEncode(_navResponse()), 200);
          }
          return http.Response(
            jsonEncode({'code': -412, 'message': 'request blocked'}),
            200,
          );
        }),
      );
      addTearDown(network.close);

      expect(
        network.getHomeFeed(),
        throwsA(
          isA<BiliApiException>().having(
            (error) => error.biliCode,
            'biliCode',
            -412,
          ),
        ),
      );
    });
  });

  group('envelope failure handling', () {
    final converter = JsonSerializableConverter(
      const {},
      envelopeFactories: {NetworkBiliHomeFeed: NetworkBiliHomeFeed.fromJson},
    );

    test('rejects a v_voucher risk-control envelope', () async {
      final response = _jsonResponse({
        'code': 0,
        'message': '0',
        'data': {'v_voucher': 'voucher-token'},
      });

      await expectLater(
        converter.convertResponse<NetworkBiliHomeFeed, dynamic>(response),
        throwsA(isA<BiliRiskControlException>()),
      );
    });

    test('rejects HTTP 412 as risk control, not a plain HTTP error', () async {
      // 创作者页投稿列表实测就是 412；归到普通 HTTP 错误后界面只能说「加载
      // 失败」，而这条其实稍后重试就能恢复。
      final response = Response<dynamic>(
        http.Response('blocked', 412),
        'blocked',
      );

      await expectLater(
        converter.convertResponse<NetworkBiliHomeFeed, dynamic>(response),
        throwsA(
          isA<BiliRiskControlException>().having(
            (error) => error.statusCode,
            'statusCode',
            412,
          ),
        ),
      );
    });

    test('keeps the HTTP status when -352 arrives on a 200 envelope', () async {
      // 非 envelope DTO 走 `ApiResult` 分支，业务码在那里才被发现；状态码必须
      // 一起带出去，否则日志里「风控」和「普通失败」分不开。
      final converter = JsonSerializableConverter(const {
        NetworkBiliHomeFeed: NetworkBiliHomeFeed.fromJson,
      });
      final response = _jsonResponse({'code': -352, 'message': 'blocked'});

      await expectLater(
        converter.convertResponse<NetworkBiliHomeFeed, dynamic>(response),
        throwsA(
          isA<BiliRiskControlException>()
              .having((error) => error.biliCode, 'biliCode', -352)
              .having((error) => error.statusCode, 'statusCode', 200),
        ),
      );
    });

    test('rejects the -352 envelope code as risk control', () async {
      final response = _jsonResponse({
        'code': -352,
        'message': '风控校验失败',
        'data': {'v_voucher': 'voucher-token'},
      });

      await expectLater(
        converter.convertResponse<NetworkBiliHomeFeed, dynamic>(response),
        throwsA(
          isA<BiliRiskControlException>().having(
            (error) => error.biliCode,
            'biliCode',
            -352,
          ),
        ),
      );
    });

    test('rejects a non-zero envelope code', () async {
      final response = _jsonResponse({
        'code': -412,
        'message': 'request blocked',
        'data': null,
      });

      await expectLater(
        converter.convertResponse<NetworkBiliHomeFeed, dynamic>(response),
        throwsA(
          isA<BiliApiException>().having(
            (error) => error.biliCode,
            'biliCode',
            -412,
          ),
        ),
      );
    });
  });
}

Response<dynamic> _jsonResponse(Map<String, dynamic> json) {
  final encoded = jsonEncode(json);
  return Response<dynamic>(
    http.Response(encoded, 200, headers: {'content-type': 'application/json'}),
    encoded,
  );
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

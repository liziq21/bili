import 'dart:convert';

import 'package:bpi/bpi.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('BiliNetworkSearch.getReplyList paginationStr encoding', () {
    test(
      'encodes standard offset safely in pagination_str query param',
      () async {
        final requests = <http.BaseRequest>[];
        final client = MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({
              'code': 0,
              'message': '0',
              'data': {'replies': []},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        final network = BiliNetworkSearch(client: client);
        addTearDown(network.close);

        await network.getReplyList(
          oid: 12345,
          type: 1,
          nextOffset: 'offset_100',
        );

        expect(requests, hasLength(1));
        final uri = requests.single.url;
        expect(uri.path, '/x/v2/reply/main');
        final paginationStr = uri.queryParameters['pagination_str'];
        expect(paginationStr, isNotNull);

        final decoded = jsonDecode(paginationStr!) as Map<String, dynamic>;
        expect(decoded, {'offset': 'offset_100'});
      },
    );

    test(
      'encodes offset with quotes and backslashes without JSON injection',
      () async {
        final requests = <http.BaseRequest>[];
        final client = MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({
              'code': 0,
              'message': '0',
              'data': {'replies': []},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        final network = BiliNetworkSearch(client: client);
        addTearDown(network.close);

        const maliciousOffset = 'offset_"injection"\\';
        await network.getReplyList(
          oid: 12345,
          type: 1,
          nextOffset: maliciousOffset,
        );

        expect(requests, hasLength(1));
        final uri = requests.single.url;
        final paginationStr = uri.queryParameters['pagination_str'];
        expect(paginationStr, isNotNull);

        // Verify it parses back cleanly without syntax errors
        final decoded = jsonDecode(paginationStr!) as Map<String, dynamic>;
        expect(decoded, {'offset': maliciousOffset});
      },
    );

    test(
      'encodes offset containing control characters and newlines safely',
      () async {
        final requests = <http.BaseRequest>[];
        final client = MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({
              'code': 0,
              'message': '0',
              'data': {'replies': []},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        final network = BiliNetworkSearch(client: client);
        addTearDown(network.close);

        const complexOffset = 'line1\nline2\r\ttab';
        await network.getReplyList(
          oid: 12345,
          type: 1,
          nextOffset: complexOffset,
        );

        expect(requests, hasLength(1));
        final uri = requests.single.url;
        final paginationStr = uri.queryParameters['pagination_str'];
        expect(paginationStr, isNotNull);

        final decoded = jsonDecode(paginationStr!) as Map<String, dynamic>;
        expect(decoded, {'offset': complexOffset});
      },
    );
  });
}

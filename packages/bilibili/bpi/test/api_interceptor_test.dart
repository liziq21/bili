import 'dart:async';
import 'dart:io';

import 'package:bpi/src/retrofit/api_interceptor.dart';
import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

final class FakeChain<BodyType> implements Chain<BodyType> {
  FakeChain(this.request);

  @override
  final Request request;

  Request? interceptedRequest;

  @override
  FutureOr<Response<BodyType>> proceed(Request request) {
    interceptedRequest = request;
    return Response(http.Response('', 200), null);
  }
}

void main() {
  group('ApiInterceptor', () {
    test(
      'applies user-agent header and query component encoded referer header',
      () async {
        const interceptor = ApiInterceptor();
        final originalRequest = Request(
          'GET',
          Uri.parse('https://api.bilibili.com/x/web-interface/wbi/search/all'),
          Uri.parse('https://api.bilibili.com/x/web-interface/wbi/search/all'),
          parameters: {'search_type': 'video', 'keyword': 'C# & Flutter?'},
        );

        final chain = FakeChain<dynamic>(originalRequest);
        await interceptor.intercept(chain);

        final resultHeaders = chain.interceptedRequest?.headers;
        expect(resultHeaders, isNotNull);
        expect(
          resultHeaders?[HttpHeaders.userAgentHeader],
          equals('Mozilla/5.0'),
        );
        expect(resultHeaders?['origin'], equals('https://search.bilibili.com'));
        expect(
          resultHeaders?[HttpHeaders.refererHeader],
          equals(
            'https://search.bilibili.com/video?keyword=C%23+%26+Flutter%3F',
          ),
        );
      },
    );

    test('sanitizes control characters in search_type and keyword', () async {
      const interceptor = ApiInterceptor();
      final originalRequest = Request(
        'GET',
        Uri.parse('https://api.bilibili.com/x/web-interface/wbi/search/all'),
        Uri.parse('https://api.bilibili.com/x/web-interface/wbi/search/all'),
        parameters: {
          'search_type': 'video\r\n',
          'keyword': 'test\x00\r\nkeyword',
        },
      );

      final chain = FakeChain<dynamic>(originalRequest);
      await interceptor.intercept(chain);

      final resultHeaders = chain.interceptedRequest?.headers;
      expect(
        resultHeaders?[HttpHeaders.refererHeader],
        equals('https://search.bilibili.com/video?keyword=testkeyword'),
      );
    });
  });
}

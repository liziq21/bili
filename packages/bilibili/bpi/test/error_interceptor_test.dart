import 'dart:async';
import 'dart:io';

import 'package:bpi/src/chopper/error_interceptor.dart';
import 'package:bpi/src/error/bpi_exception.dart';
import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'package:test/test.dart';

final Request _request = Request(
  'GET',
  Uri.parse('https://api.bilibili.com/x/web-interface/view'),
  Uri.parse('https://api.bilibili.com'),
);

final class ThrowingChain<BodyType> implements Chain<BodyType> {
  ThrowingChain(this.request, this.error);

  @override
  final Request request;

  final Object error;

  @override
  FutureOr<Response<BodyType>> proceed(Request request) async => throw error;
}

final class RecordingChain<BodyType> implements Chain<BodyType> {
  RecordingChain(this.request, this.response);

  @override
  final Request request;

  final Response<BodyType> response;

  Request? forwarded;

  @override
  FutureOr<Response<BodyType>> proceed(Request request) {
    forwarded = request;
    return response;
  }
}

void main() {
  group('BpiErrorInterceptor', () {
    test('returns the successful response it received', () async {
      const interceptor = BpiErrorInterceptor();
      final body = <String, dynamic>{'code': 0, 'data': 'payload'};
      final response = Response<Map<String, dynamic>>(
        http.Response('{"code":0,"data":"payload"}', 200),
        body,
      );
      final chain = RecordingChain<Map<String, dynamic>>(_request, response);

      final actual = await interceptor.intercept(chain);

      expect(chain.forwarded, same(_request));
      expect(actual, same(response));
      expect(actual.body, same(body));
    });

    test('rethrows a BpiException that carries a URI unchanged', () async {
      const interceptor = BpiErrorInterceptor();
      final error = BpiHttpException(
        'Bilibili request failed.',
        statusCode: 502,
        uri: _request.url,
      );
      final chain = ThrowingChain<Object?>(_request, error);

      await expectLater(interceptor.intercept(chain), throwsA(same(error)));
    });

    test('attaches the request URI to a BpiException that has none', () async {
      const interceptor = BpiErrorInterceptor();
      final cause = const FormatException('bad json');
      final error = BpiSerializationException(
        'Bilibili response is missing the data object.',
        cause: cause,
      );
      final chain = ThrowingChain<Object?>(_request, error);

      await expectLater(
        interceptor.intercept(chain),
        throwsA(
          isA<BpiSerializationException>()
              .having((e) => e.uri, 'uri', _request.url)
              .having((e) => e.message, 'message', error.message)
              .having((e) => e.cause, 'cause', same(cause)),
        ),
      );
    });

    test('maps a FormatException to BpiSerializationException', () async {
      const interceptor = BpiErrorInterceptor();
      final error = FormatException('Invalid UTF-8 byte');
      final chain = ThrowingChain<Object?>(_request, error);

      await expectLater(
        interceptor.intercept(chain),
        throwsA(
          isA<BpiSerializationException>()
              .having((e) => e.cause, 'cause', same(error))
              .having((e) => e.uri, 'uri', _request.url),
        ),
      );
    });

    test(
      'maps a CheckedFromJsonException to BpiSerializationException',
      () async {
        const interceptor = BpiErrorInterceptor();
        final error = CheckedFromJsonException(
          <String, dynamic>{},
          'room_id',
          'NetworkLiveRoomDetail',
          'Required field.',
        );
        final chain = ThrowingChain<Object?>(_request, error);

        await expectLater(
          interceptor.intercept(chain),
          throwsA(
            isA<BpiSerializationException>()
                .having((e) => e.cause, 'cause', same(error))
                .having((e) => e.uri, 'uri', _request.url),
          ),
        );
      },
    );

    test('maps a transport failure to BpiNetworkException', () async {
      const interceptor = BpiErrorInterceptor();
      final error = const SocketException('offline');
      final chain = ThrowingChain<Object?>(_request, error);

      await expectLater(
        interceptor.intercept(chain),
        throwsA(
          isA<BpiNetworkException>()
              .having((e) => e.cause, 'cause', same(error))
              .having((e) => e.uri, 'uri', _request.url),
        ),
      );
    });
  });
}

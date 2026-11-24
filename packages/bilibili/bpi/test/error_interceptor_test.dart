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
  RecordingChain(this.request);

  @override
  final Request request;

  Request? forwarded;

  @override
  FutureOr<Response<BodyType>> proceed(Request request) {
    forwarded = request;
    return Response<BodyType>(http.Response('', 200), null);
  }
}

void main() {
  group('BpiErrorInterceptor', () {
    test('passes a successful response through untouched', () async {
      const interceptor = BpiErrorInterceptor();
      final chain = RecordingChain<Object?>(_request);

      final response = await interceptor.intercept(chain);

      expect(chain.forwarded, same(_request));
      expect(response.statusCode, equals(200));
    });

    test('rethrows a BpiException unchanged', () async {
      const interceptor = BpiErrorInterceptor();
      const error = BpiHttpException(
        'Bilibili request failed.',
        statusCode: 502,
      );
      final chain = ThrowingChain<Object?>(_request, error);

      await expectLater(interceptor.intercept(chain), throwsA(same(error)));
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
            isA<BpiSerializationException>().having(
              (e) => e.cause,
              'cause',
              same(error),
            ),
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

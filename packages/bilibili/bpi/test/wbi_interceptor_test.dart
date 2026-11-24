import 'dart:async';

import 'package:bpi/src/chopper/token_manager.dart';
import 'package:bpi/src/chopper/wbi_interceptor.dart';
import 'package:bpi/src/error/bpi_exception.dart';
import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

final Uri _baseUrl = Uri.parse('https://api.bilibili.com');

const String _navBody =
    '{"code":0,"data":{"wbi_img":{'
    '"img_url":"https://i0.hdslb.com/bfs/wbi/7cd084941338484aae1ad9425b84077c.png",'
    '"sub_url":"https://i0.hdslb.com/bfs/wbi/4932caff0ff746eab6f01bf08b70ac45.png"}}}';

/// Replays [outcomes] in order: an [Object] is thrown, a [Response] returned.
final class ScriptedChain<BodyType> implements Chain<BodyType> {
  ScriptedChain(this.request, this.outcomes);

  @override
  final Request request;

  final List<Object> outcomes;

  final List<Request> attempts = [];

  @override
  FutureOr<Response<BodyType>> proceed(Request request) async {
    attempts.add(request);
    final outcome = outcomes[attempts.length - 1];
    if (outcome is Response<BodyType>) return outcome;
    throw outcome;
  }
}

void main() {
  late int keyFetches;

  setUp(() => keyFetches = 0);

  ({BiliWbiInterceptor interceptor, TokenManager tokenManager})
  buildInterceptor() {
    final tokenManager = TokenManager();
    final client = MockClient((request) async {
      keyFetches++;
      return http.Response(
        _navBody,
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    return (
      interceptor: BiliWbiInterceptor(
        tokenManager: tokenManager,
        client: client,
      ),
      tokenManager: tokenManager,
    );
  }

  final Request signedRequest = Request(
    'GET',
    Uri.parse('/x/web-interface/wbi/search/all/v2'),
    _baseUrl,
    parameters: {'keyword': 'dart'},
    tag: 'WBI',
  );

  final Response<Object?> success = Response<Object?>(
    http.Response('{"code":0}', 200),
    'ok',
  );

  test('signs a WBI request before sending it', () async {
    final (:interceptor, tokenManager: _) = buildInterceptor();
    final chain = ScriptedChain<Object?>(signedRequest, [success]);

    final response = await interceptor.intercept(chain);

    expect(response, same(success));
    expect(chain.attempts, hasLength(1));
    expect(keyFetches, equals(1));
    expect(chain.attempts.single.parameters['wts'], isNotNull);
    expect(chain.attempts.single.parameters['w_rid'], isNotNull);
    expect(chain.attempts.single.parameters['keyword'], equals('dart'));
  });

  test('retries once with a fresh key after a 401', () async {
    final (:interceptor, :tokenManager) = buildInterceptor();
    final chain = ScriptedChain<Object?>(signedRequest, [
      const BpiHttpException('Unauthorized', statusCode: 401),
      success,
    ]);

    final response = await interceptor.intercept(chain);

    expect(response, same(success));
    expect(chain.attempts, hasLength(2));
    expect(keyFetches, equals(2));
    expect(
      await tokenManager.getAccessToken(BiliWbiInterceptor.wbiStorageKey),
      isNotNull,
    );
  });

  test('does not retry other HTTP failures', () async {
    final (:interceptor, tokenManager: _) = buildInterceptor();
    const error = BpiHttpException('Server error', statusCode: 500);
    final chain = ScriptedChain<Object?>(signedRequest, [error, success]);

    await expectLater(interceptor.intercept(chain), throwsA(same(error)));
    expect(chain.attempts, hasLength(1));
  });

  test('propagates the failure of the retried request', () async {
    final (:interceptor, tokenManager: _) = buildInterceptor();
    const error = BpiHttpException('Unauthorized', statusCode: 401);
    final chain = ScriptedChain<Object?>(signedRequest, [error, error]);

    await expectLater(interceptor.intercept(chain), throwsA(same(error)));
    expect(chain.attempts, hasLength(2));
  });

  test('leaves requests without the WBI tag unsigned', () async {
    final (:interceptor, tokenManager: _) = buildInterceptor();
    final request = Request(
      'GET',
      Uri.parse('/x/web-interface/view'),
      _baseUrl,
    );
    final chain = ScriptedChain<Object?>(request, [success]);

    await interceptor.intercept(chain);

    expect(chain.attempts.single.parameters, isEmpty);
    expect(keyFetches, isZero);
  });
}

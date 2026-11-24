import 'dart:async';
import 'dart:io' show HttpStatus;

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;

import '../error/bpi_exception.dart';
import '../utils/wbi_utils.dart';
import 'token_manager.dart';

class BiliWbiInterceptor implements Interceptor {
  const BiliWbiInterceptor({required this.tokenManager, required this.client});

  final TokenManager tokenManager;
  final http.Client client;
  static const String wbiStorageKey = 'BILIBILI_MiXIN_KEY';

  @override
  Future<Response<BodyType>> intercept<BodyType>(Chain<BodyType> chain) async {
    final originalRequest = chain.request;
    if (originalRequest.tag != 'WBI') {
      return chain.proceed(originalRequest);
    }

    try {
      return await chain.proceed(await _sign(originalRequest));
    } on BpiHttpException catch (error) {
      // The response converter turns every non-2xx answer into an error before
      // it reaches this interceptor, so a rejected key arrives as a typed error
      // instead of a 401 response.
      if (error.statusCode != HttpStatus.unauthorized) rethrow;
    }

    await tokenManager.deleteToken(wbiStorageKey);
    return chain.proceed(await _sign(originalRequest));
  }

  Future<Request> _sign(Request request) async {
    final mixinKey = await tokenManager.getOrRefreshWbiKey(
      key: wbiStorageKey,
      fetcher: () => WbiUtils.fetchMixinKey(client),
    );
    return request.copyWith(
      parameters: WbiUtils.encWbi(request.parameters, mixinKey),
    );
  }
}

import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;

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

    final firstResponse = await chain.proceed(await _sign(originalRequest));
    if (firstResponse.statusCode != 401) {
      return firstResponse;
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

/// Deprecated spelling kept as a source-compatible alias.
typedef ChooperWbiInterceptor = BiliWbiInterceptor;

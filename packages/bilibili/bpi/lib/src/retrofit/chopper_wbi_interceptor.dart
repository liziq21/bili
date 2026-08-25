import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;

import '../utils/wbi_utils.dart';
import 'token_manager.dart';

import 'package:logging/logging.dart';

class ChooperWbiInterceptor({
  required final TokenManager tokenManager,
  required final http.Client client,
}) implements Interceptor {
  static const String wbiStorageKey = 'BILIBILI_MiXIN_KEY';
  final _log = Logger('ChooperWbiInterceptor');
  @override
  Future<Response<BodyType>> intercept<BodyType>(Chain<BodyType> chain) async {
    if (chain.request.tag == 'WBI') {
      var request = chain.request;

      final mixinKey = await tokenManager.getOrRefreshWbiKey(
        key: wbiStorageKey,
        fetcher: () => WbiUtils.fetchMixinKey(client),
      );
      _log.info('mixinKey: $mixinKey');
      request = request.copyWith(
        parameters: WbiUtils.encWbi(request.parameters, mixinKey),
      );

      final response = await chain.proceed(request);

      if (response.statusCode == 401) {
        await tokenManager.deleteToken(wbiStorageKey);
      }

      return response;
    }
    return chain.proceed(chain.request);
  }
}

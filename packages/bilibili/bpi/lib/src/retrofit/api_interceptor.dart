import 'dart:async';
import 'dart:io';

import 'package:chopper/chopper.dart';

class const ApiInterceptor({final bool? _enableHttp2}) implements Interceptor {
  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(
    Chain<BodyType> chain,
  ) async {
    final request = applyHeaders(chain.request, {
      HttpHeaders.userAgentHeader: 'Mozilla/5.0',
      if (_enableHttp2 != null && !_enableHttp2) 'connection': 'keep-alive',
      //HttpHeaders.acceptEncodingHeader: 'br,gzip',

      if (chain.request.parameters case {
        'search_type': final searchType,
        'keyword': final keyword,
      }) ...{
        'origin': 'https://search.bilibili.com',
        HttpHeaders.refererHeader:
            'https://search.bilibili.com/$searchType?keyword=${Uri.encodeFull(keyword)}',
      },
    });
    return chain.proceed(request);
  }
}

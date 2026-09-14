import 'dart:async';
import 'dart:io';

import 'package:chopper/chopper.dart';

final class YoutubeInnerTubeInterceptor implements Interceptor {
  const YoutubeInnerTubeInterceptor({
    this.clientVersion = '2.20230818.00.00',
  });

  final String clientVersion;

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(
    Chain<BodyType> chain,
  ) async {
    final request = chain.request;

    final updatedHeaders = Map<String, String>.from(request.headers);
    updatedHeaders[HttpHeaders.contentTypeHeader] = 'application/json';
    updatedHeaders[HttpHeaders.userAgentHeader] =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36';
    updatedHeaders['X-YouTube-Client-Name'] = '1';
    updatedHeaders['X-YouTube-Client-Version'] = clientVersion;

    final newRequest = request.copyWith(headers: updatedHeaders);
    return chain.proceed(newRequest);
  }
}

final class YoutubeRequestConverter extends JsonConverter {
  const YoutubeRequestConverter({
    this.clientName = 'WEB',
    this.clientVersion = '2.20230818.00.00',
    this.hl = 'en',
    this.gl = 'US',
  });

  final String clientName;
  final String clientVersion;
  final String hl;
  final String gl;

  Map<String, dynamic> get clientContext => {
        'context': {
          'client': {
            'clientName': clientName,
            'clientVersion': clientVersion,
            'hl': hl,
            'gl': gl,
          },
        },
      };

  @override
  Request convertRequest(Request request) {
    dynamic updatedBody = request.body;
    if (request.method == 'POST') {
      if (updatedBody is Map<String, dynamic>) {
        final bodyMap = Map<String, dynamic>.from(updatedBody);
        if (!bodyMap.containsKey('context')) {
          bodyMap['context'] = clientContext['context'];
        }
        updatedBody = bodyMap;
      } else {
        updatedBody ??= clientContext;
      }
    }

    final jsonRequest = request.copyWith(body: updatedBody);
    return super.convertRequest(jsonRequest);
  }
}

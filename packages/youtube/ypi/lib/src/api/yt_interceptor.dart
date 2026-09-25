import 'dart:async';
import 'dart:io';

import 'package:chopper/chopper.dart';

import '../client/youtube_client_config.dart';

final class YoutubeInnerTubeInterceptor implements Interceptor {
  const YoutubeInnerTubeInterceptor(this.config);

  final YoutubeClientConfig config;

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(
    Chain<BodyType> chain,
  ) async {
    final request = chain.request;
    final headers = Map<String, String>.from(request.headers);
    headers[HttpHeaders.contentTypeHeader] = 'application/json';
    headers[HttpHeaders.userAgentHeader] = config.userAgent;
    headers['X-YouTube-Client-Name'] = '1';
    headers['X-YouTube-Client-Version'] = config.clientVersion;

    return chain.proceed(request.copyWith(headers: headers));
  }
}

final class YoutubeRequestConverter extends JsonConverter {
  const YoutubeRequestConverter(this.config);

  final YoutubeClientConfig config;

  Map<String, dynamic> get clientContext => {
    'client': {
      'clientName': config.clientName,
      'clientVersion': config.clientVersion,
      'hl': config.language,
      'gl': config.country,
    },
  };

  @override
  Request convertRequest(Request request) {
    var body = request.body;
    if (request.method == 'POST') {
      if (body is Map) {
        final bodyMap = body.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        if (!bodyMap.containsKey('context')) {
          bodyMap['context'] = clientContext;
        }
        body = bodyMap;
      } else {
        body ??= {'context': clientContext};
      }
    }
    return super.convertRequest(request.copyWith(body: body));
  }
}

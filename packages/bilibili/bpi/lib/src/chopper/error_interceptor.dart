import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:json_annotation/json_annotation.dart';

import '../error/bpi_exception.dart';

/// Maps every failure inside the Chopper pipeline onto a [BpiException].
///
/// Chopper runs user interceptors outside its response and error converters,
/// so the interceptor placed first in `ChopperClient.interceptors` sees all of
/// it: transport errors from the HTTP client, the JSON decoder's
/// `FormatException`s and the exceptions the converters and DTO factories
/// raise. Translating here keeps the endpoint methods free of the identical
/// try/catch block they used to repeat.
final class BpiErrorInterceptor implements Interceptor {
  const BpiErrorInterceptor();

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(
    Chain<BodyType> chain,
  ) async {
    final uri = chain.request.url;
    try {
      return await chain.proceed(chain.request);
    } on BpiException catch (error, stack) {
      if (error.uri != null) rethrow;
      Error.throwWithStackTrace(error.withUri(uri), stack);
    } on FormatException catch (error) {
      // Chopper decodes JSON bodies with utf8.decode before the converter's
      // tolerant parsing, so invalid bytes surface as a FormatException here.
      throw BpiSerializationException(
        'Bilibili response is not valid JSON.',
        uri: uri,
        cause: error,
      );
    } on CheckedFromJsonException catch (error) {
      throw BpiSerializationException(
        'Bilibili response does not match the expected API model.',
        uri: uri,
        cause: error,
      );
    } on Object catch (error) {
      throw BpiNetworkException(
        'Bilibili request failed.',
        uri: uri,
        cause: error,
      );
    }
  }
}

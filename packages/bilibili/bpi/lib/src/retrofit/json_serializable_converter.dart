import 'dart:async';

import 'package:chopper/chopper.dart';

import '../error/bpi_exception.dart';
import '../model/api_result.dart';

typedef JsonFactory<T> = T Function(Map<String, dynamic> json);

class const JsonSerializableConverter(final Map<Type, JsonFactory> factories)
    extends JsonConverter {
  @override
  FutureOr<Response<ResultType>> convertResponse<ResultType, Item>(
    Response response,
  ) async {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BpiHttpException(
        'Bilibili request failed.',
        statusCode: response.statusCode,
      );
    }

    // use [JsonConverter] to decode json
    final jsonRes = await super.convertResponse(response);
    final jsonFactory = factories[ResultType];
    if (jsonFactory == null || jsonFactory is! JsonFactory<ResultType>) {
      throw BpiSerializationException(
        'No JSON factory is registered for $ResultType.',
      );
    }
    if (jsonRes.body is! Map) {
      throw BpiSerializationException(
        'Expected a JSON object for $ResultType but received '
        '${jsonRes.body.runtimeType}.',
      );
    }

    final apiResult = ApiResult<ResultType>.fromJson(
      Map<String, dynamic>.from(jsonRes.body as Map),
      jsonFactory,
    );
    return switch (apiResult) {
      Ok(:final data) => jsonRes.copyWith<ResultType>(body: data),
      Error(:final code, :final message) => throw BiliApiException(
        message ?? 'Bilibili API request failed.',
        biliCode: code,
        statusCode: response.statusCode,
      ),
    };
  }

  @override
  // all objects should implements toJson method
  // ignore: unnecessary_overrides
  Request convertRequest(Request request) => super.convertRequest(request);

  @override
  FutureOr<Response> convertError<ResultType, Item>(Response response) {
    // use [JsonConverter] to decode json
    return super.convertError(response);
  }
}

import 'dart:async';

import 'package:chopper/chopper.dart';

import '../error/bpi_exception.dart';
import '../model/api_result.dart';

typedef JsonFactory<T> = T Function(Map<String, dynamic> json);

class const JsonSerializableConverter(
  final Map<Type, JsonFactory> factories, {
  final Map<Type, JsonFactory> envelopeFactories = const {},
}) extends JsonConverter {
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

    final jsonRes = await super.convertResponse(response);
    if (jsonRes.body is! Map) {
      throw BpiSerializationException(
        'Expected a JSON object for $ResultType but received '
        '${jsonRes.body.runtimeType}.',
      );
    }
    final json = Map<String, dynamic>.from(jsonRes.body as Map);

    final envelopeFactory = envelopeFactories[ResultType];
    if (envelopeFactory is JsonFactory<ResultType>) {
      return jsonRes.copyWith<ResultType>(body: envelopeFactory(json));
    }

    final jsonFactory = factories[ResultType];
    if (jsonFactory is! JsonFactory<ResultType>) {
      throw BpiSerializationException(
        'No JSON factory is registered for $ResultType.',
      );
    }

    final apiResult = ApiResult<ResultType>.fromJson(json, jsonFactory);
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
  FutureOr<Response> convertError<ResultType, Item>(Response response) {
    throw BpiHttpException(
      'Bilibili request failed.',
      statusCode: response.statusCode,
    );
  }
}

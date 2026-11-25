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
    if (response.statusCode == biliRiskControlStatusCode) {
      throw BiliRiskControlException(
        'Bilibili rejected the request with a risk-control status.',
        statusCode: response.statusCode,
      );
    }
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
      _rejectEnvelopeFailure(json, response.statusCode);
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

  /// Envelope DTOs parse `code`/`data` themselves, so the shared risk-control
  /// and error handling in [ApiResult] would otherwise be skipped for them.
  void _rejectEnvelopeFailure(Map<String, dynamic> json, int statusCode) {
    final code = switch (json['code']) {
      num value => value.toInt(),
      String value => int.tryParse(value),
      _ => null,
    };
    if (isBiliRiskControlCode(code)) {
      throw BiliRiskControlException(
        json['message']?.toString() ?? 'Bilibili risk-control rejection.',
        biliCode: code,
        statusCode: statusCode,
      );
    }
    if (code != null && code != 0) {
      throw BiliApiException(
        json['message']?.toString() ?? 'Bilibili API request failed.',
        biliCode: code,
        statusCode: statusCode,
      );
    }
    final rawData = json['data'];
    if (rawData is Map &&
        isBiliRiskControlChallenge(Map<String, dynamic>.from(rawData))) {
      throw BiliRiskControlException(
        'Bilibili answered with a risk-control challenge instead of data.',
        biliCode: code,
      );
    }
  }

  @override
  FutureOr<Response> convertError<ResultType, Item>(Response response) {
    if (response.statusCode == biliRiskControlStatusCode) {
      throw BiliRiskControlException(
        'Bilibili rejected the request with a risk-control status.',
        statusCode: response.statusCode,
      );
    }
    throw BpiHttpException(
      'Bilibili request failed.',
      statusCode: response.statusCode,
    );
  }
}

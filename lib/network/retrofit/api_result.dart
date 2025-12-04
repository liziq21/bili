import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'api_result.freezed.dart';

@Freezed(genericArgumentFactories: true)
sealed class ApiResult<T> with _$ApiResult<T> {
  const factory ApiResult({
    required int code,
    required T data,
  }) = ApiResultOk;

  const factory ApiResult.error({ // 建议给错误工厂方法一个不同的名称，避免与另一个冲突
    required int code,
    String? message,
  }) = ApiResultError;

  factory ApiResult.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    final code = json['code'] as int? ?? -1;
    final message = json['message'] as String?;
    final rawData = json['data'] ?? json['result'];

    if ((code != 0 && code != 3)||(message != null && message.isNotEmpty)) {
      return ApiResultError(code: code, message: message);
    }


    if (rawData == null) {
      return ApiResultError(
        code: code,
        message: 'Data or result field is missing for a successful response.',
      );
    }

    try {
      return ApiResultOk(
        code: code,
        data: fromJsonT(rawData as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResultError(
        code: code,
        message: 'Failed to parse data: $e',
      );
    }
  }
}
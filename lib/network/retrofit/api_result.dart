import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'api_result.freezed.dart';

@Freezed(genericArgumentFactories: true)
sealed class ApiResult<T> with _$ApiResult<T> {
  const factory ApiResult.ok({
    required int code,
    required T data,
  }) = ApiResultOk;

  const factory ApiResult.error({
    required int code,
    String? message,
  }) = ApiResultError;

  factory ApiResult.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    final code = json['code'] as int;
    final message = json['message'] as String?;

    if (code != 0 && code != 3
        ||(message != null && message.isNotEmpty && message != '0')
    ) {
      return ApiResultError(code: code, message: message);
    }
    
    final data = (json['data'] ?? json['result']) as Map<String, dynamic>;
    return ApiResultOk(
      code: code,
      data: fromJsonT(data),
    );
  }
}
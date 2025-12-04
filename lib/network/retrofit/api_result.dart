import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'api_result.freezed.dart';
part 'api_result.g.dart';

@Freezed(genericArgumentFactories: true)
sealed class ApiResult<T> with _$ApiResult<T> {
  const factory ApiResult({
    required int code,
    required T data,
  }) = ApiResultOk;
  
  const factory ApiResult({
    required int code,
    String? message
  }) = ApiResultError;
  
  factory ApiResult.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) {
    final {
      'code': int code,
      'message': String? message,
      'data': T? data,
      'result': T? result,
    } = json;
    
    if(code != 0 && message != null && message.isNotEmpty) {
      return ApiResultError(code: code, message: json);
    }
    
    return ApiResultOk(
      code: code,
      data: fromJsonT(data ?? result!),
    );
  }
}

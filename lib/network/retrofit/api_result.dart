import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'api_result.freezed.dart';
part 'api_result.g.dart';

@Freezed(genericArgumentFactories: true)
sealed class ApiResult<T> with _$ApiResult<T> {
  //const factory ApiResult() = 

  const factory ApiResult.ok(T data) = ApiResultOk;
  const factory ApiResult.error(
    int code,
    String message,
    int ttl,
  ) = ApiResultError;
  
  factory ApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
    _$ApiResultFromJson(json, fromJsonT);
}


import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'api_result.freezed.dart';
part 'api_result.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class ApiResult<T> with _$ApiResult<T> {
  const factory ApiResult(
    int code,
    String message,
    int ttl,
    T? data,
  ) = _ApiResult;
  
  factory ApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object) fromJsonT,
  ) =>
    _$ApiResultFromJson(json, fromJsonT);
}


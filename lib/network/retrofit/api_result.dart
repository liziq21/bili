import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_result.freezed.dart';
part 'api_result.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class ApiResult<T> with _$ApiResult<T> {
  const factory ApiResult({
    required int code,
    required String message,
    required T data,
  }) = _ApiResult;
  
  factory ApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
    _$ApiResultFromJson(json, fromJsonT);
}


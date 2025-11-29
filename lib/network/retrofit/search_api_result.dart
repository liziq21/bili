import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_api_result.freezed.dart';
part 'search_api_result.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class SearchApiResult<T> with _$ApiResult<T> {
  const factory SearchApiResult(
    required int code,
    required T result,
  ) = _SearchApiResult;
  
  factory SearchApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
    _$SearchApiResultFromJson(json, fromJsonT);
}
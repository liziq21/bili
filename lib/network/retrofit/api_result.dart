import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_result.freezed.dart';
part 'api_result.g.dart';

@Freezed(genericArgumentFactories: true)
sealeed class ApiResult<T> with _$ApiResult<T> {
  const factory ApiResult({
    required int code,
    String? message,
    T? data,
  }) = ApiResultOk;
  
  factory ApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  const factory ApiResult({
    required int code,
    String? message,
    T? data,
  }) = ApiResultOk;
  
  factory ApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) {
    if (json.isEmpty) {
      json['message']
    }
    fromJsonT
  }
}


@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
sealeed class NetworkSearchResult with _$NetworkSearchResult {

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory NetworkSearchResult.article(
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApiResult<T> _$ApiResultFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => $checkedCreate('_ApiResult', json, ($checkedConvert) {
  final val = _ApiResult<T>(
    $checkedConvert('code', (v) => (v as num).toInt()),
    $checkedConvert('message', (v) => v as String),
    $checkedConvert('ttl', (v) => (v as num).toInt()),
    $checkedConvert('data', (v) => fromJsonT(v)),
  );
  return val;
});

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiResultOk<T> _$ApiResultOkFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => $checkedCreate('ApiResultOk', json, ($checkedConvert) {
  final val = ApiResultOk<T>(
    $checkedConvert('data', (v) => fromJsonT(v)),
    $type: $checkedConvert('runtimeType', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {r'$type': 'runtimeType'});

ApiResultError<T> _$ApiResultErrorFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => $checkedCreate('ApiResultError', json, ($checkedConvert) {
  final val = ApiResultError<T>(
    $checkedConvert('code', (v) => (v as num).toInt()),
    $checkedConvert('message', (v) => v as String),
    $checkedConvert('ttl', (v) => (v as num).toInt()),
    $type: $checkedConvert('runtimeType', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {r'$type': 'runtimeType'});

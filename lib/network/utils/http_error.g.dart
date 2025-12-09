// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HttpError _$HttpErrorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_HttpError', json, ($checkedConvert) {
      final val = _HttpError(
        code: $checkedConvert('code', (v) => v as String? ?? "ERROR"),
        message: $checkedConvert('message', (v) => v as String),
        stack: $checkedConvert('stack', (v) => v as String?),
      );
      return val;
    });

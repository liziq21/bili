// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_page_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkPageinfo _$NetworkPageinfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NetworkPageinfo', json, ($checkedConvert) {
      final val = NetworkPageinfo(
        total: $checkedConvert('total', (v) => (v as num).toInt()),
        numResults: $checkedConvert('numResults', (v) => (v as num).toInt()),
        pages: $checkedConvert('pages', (v) => (v as num).toInt()),
      );
      return val;
    });

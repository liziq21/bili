// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_search.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NetworkSearch _$NetworkSearchFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_NetworkSearch', json, ($checkedConvert) {
      final val = _NetworkSearch(
        $checkedConvert('page', (v) => (v as num).toInt()),
        $checkedConvert('pagesize', (v) => (v as num).toInt()),
        $checkedConvert('numResults', (v) => (v as num).toInt()),
        $checkedConvert('numPages', (v) => (v as num).toInt()),
        $checkedConvert('pageinfo', (v) => _pageinfoMapFromJson(v)),
        $checkedConvert('result', (v) => _resultMapFromJson(v as Object)),
      );
      return val;
    });

_NetworkPageinfo _$NetworkPageinfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_NetworkPageinfo', json, ($checkedConvert) {
      final val = _NetworkPageinfo(
        $checkedConvert('total', (v) => (v as num).toInt()),
        $checkedConvert('numResults', (v) => (v as num).toInt()),
        $checkedConvert('pages', (v) => (v as num).toInt()),
      );
      return val;
    });

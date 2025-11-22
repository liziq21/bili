// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_search.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NetworkSearch _$NetworkSearchFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_NetworkSearch',
      json,
      ($checkedConvert) {
        final val = _NetworkSearch(
          $checkedConvert('page', (v) => (v as num).toInt()),
          $checkedConvert('pagesize', (v) => (v as num).toInt()),
          $checkedConvert('num_results', (v) => (v as num).toInt()),
          $checkedConvert('num_pages', (v) => (v as num).toInt()),
          $checkedConvert('pageinfo', (v) => _pageinfoMapFromJson(v as Object)),
          $checkedConvert('result', (v) => _resultMapFromJson(v as Object)),
        );
        return val;
      },
      fieldKeyMap: const {'numResults': 'num_results', 'numPages': 'num_pages'},
    );

_NetworkPageinfo _$NetworkPageinfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_NetworkPageinfo', json, ($checkedConvert) {
      final val = _NetworkPageinfo(
        $checkedConvert('total', (v) => (v as num).toInt()),
        $checkedConvert('num_results', (v) => (v as num).toInt()),
        $checkedConvert('pages', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'numResults': 'num_results'});

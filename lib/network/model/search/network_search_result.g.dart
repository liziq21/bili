// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NetworkSearchResult _$NetworkSearchResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_NetworkSearchResult', json, ($checkedConvert) {
      final val = _NetworkSearchResult(
        page: $checkedConvert('page', (v) => (v as num).toInt()),
        pagesize: $checkedConvert('pagesize', (v) => (v as num).toInt()),
        numResults: $checkedConvert('numResults', (v) => (v as num).toInt()),
        numPages: $checkedConvert('numPages', (v) => (v as num).toInt()),
        pageinfo: $checkedConvert(
          'pageinfo',
          (v) => _pageinfoFromJson(v as Map<String, dynamic>?),
        ),
        result: $checkedConvert(
          'result',
          (v) => NetworkSearchResultWrapper.fromJson(v),
        ),
      );
      return val;
    });

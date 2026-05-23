// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_search_suggest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NetworkSearchSuggest _$NetworkSearchSuggestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_NetworkSearchSuggest', json, ($checkedConvert) {
  final val = _NetworkSearchSuggest(
    tag: $checkedConvert(
      'tag',
      (v) => (v as List<dynamic>)
          .map(
            (e) => NetworkSearchSuggestItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
  );
  return val;
});

_NetworkSearchSuggestItem _$NetworkSearchSuggestItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_NetworkSearchSuggestItem', json, ($checkedConvert) {
  final val = _NetworkSearchSuggestItem(
    term: $checkedConvert('term', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
  );
  return val;
});

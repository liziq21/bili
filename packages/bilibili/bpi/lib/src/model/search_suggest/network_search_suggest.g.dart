// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_search_suggest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkSearchSuggest _$NetworkSearchSuggestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkSearchSuggest', json, ($checkedConvert) {
  final val = NetworkSearchSuggest(
    tag: $checkedConvert(
      'tag',
      (v) =>
          (v as List<dynamic>?)
              ?.map(
                (e) => NetworkSearchSuggestItem.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    ),
  );
  return val;
});

NetworkSearchSuggestItem _$NetworkSearchSuggestItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkSearchSuggestItem', json, ($checkedConvert) {
  final val = NetworkSearchSuggestItem(
    term: $checkedConvert('term', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
  );
  return val;
});

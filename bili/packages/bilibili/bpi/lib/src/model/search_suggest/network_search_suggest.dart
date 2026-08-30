//import 'package:freezed_annotation/freezed_annotation.dart';

//part 'network_search_suggest.freezed.dart';

import 'package:json_annotation/json_annotation.dart';

part 'network_search_suggest.g.dart';

@JsonSerializable(createToJson: false)
class const NetworkSearchSuggest({
  required final List<NetworkSearchSuggestItem> tag,
}) {
  factory NetworkSearchSuggest.fromJson(Map<String, dynamic> json) =>
      _$NetworkSearchSuggestFromJson(json);
}

@JsonSerializable(createToJson: false)
class const NetworkSearchSuggestItem({
  required final String term,
  required final String name,
}) {
  factory NetworkSearchSuggestItem.fromJson(Map<String, dynamic> json) =>
      _$NetworkSearchSuggestItemFromJson(json);
}

// @freezed
// abstract class NetworkSearchSuggest with _$NetworkSearchSuggest {
//   const factory NetworkSearchSuggest({
//     required List<NetworkSearchSuggestItem> tag,
//   }) = _NetworkSearchSuggest;
//
//   factory NetworkSearchSuggest.fromJson(Map<String, dynamic> json) =>
//       _$NetworkSearchSuggestFromJson(json);
// }
//
// @freezed
// abstract class NetworkSearchSuggestItem with _$NetworkSearchSuggestItem {
//   const factory NetworkSearchSuggestItem({
//     required String term,
//     required String name,
//   }) = _NetworkSearchSuggestItem;
//
//   factory NetworkSearchSuggestItem.fromJson(Map<String, dynamic> json) =>
//       _$NetworkSearchSuggestItemFromJson(json);
// }

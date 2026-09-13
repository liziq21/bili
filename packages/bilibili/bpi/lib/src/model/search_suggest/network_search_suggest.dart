import 'package:json_annotation/json_annotation.dart';

part 'network_search_suggest.g.dart';

@JsonSerializable(createToJson: false)
class const NetworkSearchSuggest({
  @JsonKey(defaultValue: []) required final List<NetworkSearchSuggestItem> tag,
}) {
  factory NetworkSearchSuggest.fromJson(Map<String, dynamic> json) {
    final target = json['result'] is Map<String, dynamic>
        ? json['result'] as Map<String, dynamic>
        : json;
    return _$NetworkSearchSuggestFromJson(target);
  }
}

@JsonSerializable(createToJson: false)
class const NetworkSearchSuggestItem({
  required final String term,
  required final String name,
}) {
  factory NetworkSearchSuggestItem.fromJson(Map<String, dynamic> json) =>
      _$NetworkSearchSuggestItemFromJson(json);
}

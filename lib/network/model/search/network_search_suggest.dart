import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_search_suggest.freezed.dart';
part 'network_search_suggest.g.dart';

@freezed
abstract class NetworkSearchSuggest with _$NetworkSearchSuggest {

  const factory NetworkSearchSuggest(
    List<NetworkSearchSuggestItem>? tag,
  ) = _NetworkSearchSuggest;

  factory NetworkSearchSuggest.fromJson(Map<String, dynamic> json)
    => _$NetworkSearchSuggestFromJson(json);
    
}

@freezed
abstract class NetworkSearchSuggestItem with _$NetworkSearchSuggestItem {

  const factory NetworkSearchSuggestItem(
    String term,
    String name,
  ) = _NetworkSearchSuggestItem;
  
  factory NetworkSearchSuggestItem.fromJson(Map<String, dynamic> json)
    => _$NetworkSearchSuggestItemFromJson(json);

}

//import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'common/network_page_info.dart';
import 'network_search_result_wrapper.dart';
import '../../search_result_type.dart';

//part 'network_search_result.freezed.dart';
part 'network_search_result.g.dart';

// @freezed
// abstract class NetworkSearchResult with _$NetworkSearchResult {
//   const factory NetworkSearchResult({
//     required int page,
//     required int pagesize,
//     required int numResults,
//     required int numPages,
//     @JsonKey(fromJson: _pageinfoFromJson)
//     Map<SearchResultType, NetworkPageinfo>? pageinfo,
//     required NetworkSearchResultWrapper result,
//   }) = _NetworkSearchResult;
//
//   factory NetworkSearchResult.fromJson(Map<String, dynamic> json) =>
//       _$NetworkSearchResultFromJson(json);
// }
@JsonSerializable()
class NetworkSearchResult({
  required final int page,
  required final int pagesize,
  required final int numResults,
  required final int numPages,
  @JsonKey(fromJson: _pageinfoFromJson)
  required final Map<SearchResultType, NetworkPageinfo>? pageinfo,
  required final NetworkSearchResultWrapper result,
}) {
  factory fromJson(Map<String, dynamic> json) =>
      _$NetworkSearchResultFromJson(json);
}

Map<SearchResultType, NetworkPageinfo>? _pageinfoFromJson(
  Map<String, dynamic>? json,
) {
  if (json == null) {
    return null;
  }
  return {
    for (final MapEntry(:key, :value as Map<String, dynamic>) in json.entries)
      ?SearchResultType.parse(key): NetworkPageinfo.fromJson(value),
  };
}

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../bili/search_result_type.dart';
import 'common/network_page_info.dart';
import 'network_search_result_wrapper.dart';

part 'network_search_result.freezed.dart';
part 'network_search_result.g.dart';

@freezed
abstract class NetworkSearchResult with _$NetworkSearchResult {
  const factory NetworkSearchResult({
    required int page,
    required int pagesize,
    required int numResults,
    required int numPages,
    @JsonKey(fromJson: _pageinfoFromJson)
    Map<SearchResultType, NetworkPageinfo>? pageinfo,
    required NetworkSearchResultWrapper result,
  }) = _NetworkSearchResult;
  
Map<SearchResultType, NetworkPageinfo>? _pageinfoFromJson(dynamic json) {
  return json == null ? null
    : {
      for (final entry in (json as Map<String, dynamic>).entries)
        ?SearchResultType.parse(
          entry.key
        ):
        NetworkPageinfo.fromJson(
          entry.value as Map<String, dynamic>
        ),
    };
}

  
  factory NetworkSearchResult.fromJson(Map<String, dynamic> json)
    => _$NetworkSearchResultFromJson(json);
}


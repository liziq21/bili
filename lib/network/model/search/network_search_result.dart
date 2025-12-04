import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../bili/search_result_type.dart';
import 'common/network_page_info.dart';
import 'network_search_result_wrapper.dart';

part 'network_search_result.freezed.dart';
part 'network_search_result.g.dart';

@freezed
abstract class NetworkSearchResult with _$NetworkSearchResult {
  const NetworkSearchResult({
    required int page,
    required int pagesize,
    required int numResults,
    required int numPages,
    @JsonKey(fromJson: _pageinfoFromJson)
    Map<SearchResultType, NetworkPageinfo>? pageinfo,
    required NetworkSearchResultWrapper result,
  }) = _NetworkSearchResult;
  
  Map<SearchResultType, NetworkPageinfo>? _pageinfoFromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return {
        for (final MapEntry(:key, :value) in json.entries)
          if (value is Map<String, dynamic>)
            ?SearchResultType.parse(key): NetworkPageinfo.fromJson(value),
      };
    }
    return null;
  }
  
  factory NetworkSearchResult.fromJson(Map<String, dynamic> json)
    => _$NetworkSearchResultFromJson(json);
}


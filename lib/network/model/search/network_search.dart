import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:f_biuli/bili/search_result_type.dart';
import 'network_search_result.dart';

part 'network_search.freezed.dart';
part 'network_search.g.dart';

@freezed
abstract class NetworkSearch with _$NetworkSearch {
  const factory NetworkSearch(
    int page,
    int pagesize,
    int numResults,
    int numPages,
    @JsonKey(fromJson: _pageinfoMapFromJson)
    Map<SearchResultType, NetworkPageinfo>? pageinfo,
    @JsonKey(fromJson: _resultMapFromJson)
    Map<SearchResultType, List<NetworkSearchResult>?> result,
  ) = _NetworkSearch;
  
  factory NetworkSearch.fromJson(Map<String, dynamic> json)
    => _$NetworkSearchFromJson(json);
}

Map<SearchResultType, NetworkPageinfo>? _pageinfoMapFromJson(dynamic json) {
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
  
Map<SearchResultType, List<NetworkSearchResult>?> _resultMapFromJson(Object json) {

    List<NetworkSearchResult>? _resultsFromJson(dynamic results) {
      return (results as List?)
        ?.map((e) => NetworkSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
    }
    
    if (json is List) {
      if (json.isEmpty) return {};
      
      final resultItem1 = json[0] as Map<String, dynamic>;
      // 综合搜索结果
      if (resultItem1.containsKey('result_type')) {
        return {
          for (final e in json)
            ?SearchResultType.parse(
              (e as Map<String, dynamic>)['result_type'] as String
            ):
            _resultsFromJson(
              e['data']
            ),
        };
      }
      
      // 其它类型搜索结果
      return {
        ?SearchResultType.parse(
          resultItem1['type'] as String
        ):
        _resultsFromJson(json),
      };
    
    // live 类型搜索结果
    } else if (json is Map<String, dynamic>) {
      return {
        for (var entry in json.entries)
          ?SearchResultType.parse(entry.key): _resultsFromJson(entry.value),
      };
    }
    
    return {};
  }


@freezed
abstract class NetworkPageinfo with _$NetworkPageinfo {
  const factory NetworkPageinfo(
    int total,
    int numResults,
    int pages,
  ) = _NetworkPageinfo;
  
  factory NetworkPageinfo.fromJson(Map<String, dynamic> json)
    => _$NetworkPageinfoFromJson(json);
}

extension MappableListExtension<K, V> on Iterable<MapEntry<K, V>> {
  Map<K, V> toMap() => Map.fromEntries(this);
}
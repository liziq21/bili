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

Map<SearchResultType, NetworkPageinfo> _pageinfoMapFromJson(Object json) {
  return {
    for (var entry in (json as Map<String, dynamic>).entries)
      SearchResultType.parse(entry.key): NetworkPageinfo.fromJson(entry.value as Map<String, dynamic>),
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
      
      // 综合搜索结果
      if ((json[0] as Map<String, dynamic>).containsKey('result_type')) {
        return {
          for (var entry in json)
            (entry as Map<String, dynamic>)['data'] as Map<String, dynamic> dataMap:
              SearchResultType.parse(dataMap['type']): _resultsFromJson(dataMap),
        };
      // 其它类型搜索结果
      } else {
        final type = (json[0] as Map<String, dynamic>)['type'];
        return { SearchResultType.parse(type): _resultsFromJson(json) };
      }
    }
    
    // live 类型搜索结果
    return {
      for (var entry in (json as Map<String, dynamic>).entries)
        SearchResultType.parse(entry.key): _resultsFromJson(entry.value),
    };
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
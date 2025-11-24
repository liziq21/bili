import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:f_biuli/bili/search_result_type.dart';
import 'network_search_result.dart';

part 'network_search.freezed.dart';
part 'network_search.g.dart';

@Freezed(unionValueCase: FreezedUnionCase.none)
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
    return (json as Map<String, dynamic>).entries
      .map((e) => MapEntry(
          SearchResultType.parse(e.key),
          NetworkPageinfo.fromJson(e.value as Map<String, dynamic>)
      ))
      .toMap();
  }
  
  Map<SearchResultType, List<NetworkSearchResult>?> _resultMapFromJson(Object json) {

    List<NetworkSearchResult>? _resultsFromJson(dynamic results) {
      return (results as List?)
        ?.map((e) => NetworkSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
    }
    
    if (json is List) {
      
      // 综合搜索结果
      if ((json[0] as Map<String, dynamic>).containsKey('result_type')) {
        return json
          .map((e) {
            final resultMap = e as Map<String, dynamic>;
            final type = SearchResultType.parse(resultMap['type']);
            final results = resultMap['data'];
            return MapEntry(type, _resultsFromJson(results));
          })
          .toMap();
      
      // 其它类型搜索结果
      } else {
        return json
          .map((e) {
            final results = e as Map<String, dynamic>;
            final type = SearchResultType.parse(results['type']);
            return MapEntry(type, _resultsFromJson(results));
          })
          .toMap();
      }
    
    // live 类型搜索结果
    } else if (json is Map<String, dynamic>) {
      json.entries
        .map((entry) {
          final type = SearchResultType.parse(entry.key);
          final results = entry.value;
          return MapEntry(type, _resultsFromJson(results));
        })
        .toMap();
    }
    
    throw ArgumentError.value(json, 'json', 'Cannot convert the provided data.');
  }


@Freezed(unionValueCase: FreezedUnionCase.none)
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
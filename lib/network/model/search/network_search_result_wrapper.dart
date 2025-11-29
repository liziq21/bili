import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../bili/search_result_type.dart';
import 'concrete_results/network_article_search_result.dart';
import 'concrete_results/network_bili_user_search_result.dart';
import 'concrete_results/network_media_bangumi_search_result.dart';
import 'concrete_results/network_media_ft_search_result.dart';
import 'concrete_results/network_live_room_search_result.dart';
import 'concrete_results/network_live_user_search_result.dart';
import 'concrete_results/network_video_search_result.dart';

part 'network_search_result_wrapper.freezed.dart';
part 'network_search_result_wrapper.g.dart';

@freezed
abstract class NetworkSearchResultWrapper with _$NetworkSearchResult {
  const factory NetworkSearchResultWrapper({
    @Default([]) List<NetworkArticleSearchResult> article,
    @Default([]) List<NetworkBiliUserSearchResult> biliUser,
    @Default([]) List<NetworkMediaBangumiSearchResult> mediaBangumi,
    @Default([]) List<NetworkMediaFtSearchResult> mediaFt,
    @Default([]) List<NetworkLiveRoomSearchResult> liveRoom,
    @Default([]) List<NetworkLiveUserSearchResult> liveUser,
    @Default([]) List<NetworkVideoSearchResult> video,
  }) = _NetworkSearchResultWrapper;
  
  factory NetworkSearchResultWrapper.fromJson(dynamic json) {
    List<NetworkBiliUserSearchResult> biliUser = [];
    List<NetworkMediaBangumiSearchResult> mediaBangumi= [];
    List<NetworkMediaFtSearchResult> mediaFt= [];
    List<NetworkLiveRoomSearchResult> liveRoom= [];
    List<NetworkLiveUserSearchResult> liveUser= [];
    List<NetworkVideoSearchResult> video= [];
    
    void _parseAndAssignResults(String type, dynamic results) {
      if (results !is List || results.isEmpty) {
        return;
      }
      
      List<T> _mapAndConvert<T>(T Function(Map<String, dynamic> json) fromJsonFactory) {
        return data.map((e) => fromJsonFactory(e as Map<String, dynamic>)).toList();
      }
      
      switch (type) {
        case 'article':
          articleResults = _mapAndConvert(NetworkArticleSearchResult.fromJson);
        case 'bili_user':
          biliUserResults = _mapAndConvert(NetworkBiliUserSearchResult.fromJson);
        case 'media_bangumi':
          mediaBangumiResults = _mapAndConvert(NetworkMediaBangumiSearchResult.fromJson);
        case 'media_ft':
          mediaFtResults = _mapAndConvert(NetworkMediaFtSearchResult.fromJson);
        case 'live_room':
          liveRoomResults = _mapAndConvert(NetworkLiveRoomSearchResult.fromJson);
        case 'live_user':
          liveUserResults = _mapAndConvert(NetworkLiveUserSearchResult.fromJson);
        case 'video':
          videoResults = _mapAndConvert(NetworkVideoSearchResult.fromJson);
        default:
      }
    }

    if (json is List) {
      if (json.isEmpty) {
        return const NetworkSearchResultWrapper();
      }
      
      final firstItem = json.first as Map<String, dynamic>;
      if (firstItem && firstItem.containsKey('result_type')) {
        // 综合搜索结果
        for (final { 'result_type': String type, 'data': dynamic data } in json) {
          _parseAndAssignResults(type, data);
        }
      }
      
      // 其它类型搜索结果
      _parseAndAssignResults(firstItem['type'] as String, json)

    // live 类型搜索结果 Map is {'live_room': data, 'live_user': data}
    } else if (json is Map<String, dynamic>) {
        for (final MapEntry(key: type, value: result) in json.entries) {
          _parseAndAssignResults(type, result);
        }
    }
    
    return NetworkSearchResultWrapper(
      article: articleResults,
      biliUser: biliUserResults,
      mediaBangumi: mediaBangumiResults,
      mediaFt: mediaFtResults,
      liveRoom: liveRoomResults,
      liveUser: liveUserResults,
      video: videoResults,
    );
  }
}
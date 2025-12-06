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

@freezed
abstract class NetworkSearchResultWrapper with _$NetworkSearchResultWrapper {
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
    List<NetworkArticleSearchResult> articleResults = [];
    List<NetworkBiliUserSearchResult> biliUserResults = [];
    List<NetworkMediaBangumiSearchResult> mediaBangumiResults = [];
    List<NetworkMediaFtSearchResult> mediaFtResults = [];
    List<NetworkLiveRoomSearchResult> liveRoomResults = [];
    List<NetworkLiveUserSearchResult> liveUserResults = [];
    List<NetworkVideoSearchResult> videoResults = [];
    
    void _parseAndAssignResults(String type, dynamic results) {
      if (results == null) {
        return;
      }
      
      final resultsList = results as List;
      if (resultsList.isEmpty) {
        return;
      }
      
      List<T> _mapAndConvert<T>(T Function(Map<String, dynamic>) fromJsonFactory) {
        return resultsList.map((e) => 
          fromJsonFactory(e as Map<String, dynamic>)
        ).toList();
      }
      
      switch (SearchResultType.parse(type)) {
        case .article:
          articleResults = _mapAndConvert(NetworkArticleSearchResult.fromJson);
        case .biliUser:
          biliUserResults = _mapAndConvert(NetworkBiliUserSearchResult.fromJson);
        case .mediaBangumi:
          mediaBangumiResults = _mapAndConvert(NetworkMediaBangumiSearchResult.fromJson);
        case .mediaFt:
          mediaFtResults = _mapAndConvert(NetworkMediaFtSearchResult.fromJson);
        case .liveRoom:
          liveRoomResults = _mapAndConvert(NetworkLiveRoomSearchResult.fromJson);
        case .liveUser:
          liveUserResults = _mapAndConvert(NetworkLiveUserSearchResult.fromJson);
        case .video:
          videoResults = _mapAndConvert(NetworkVideoSearchResult.fromJson);
        default:
      }
    }

    if (json is List) {
      if (json.isEmpty) {
        return const NetworkSearchResultWrapper();
      }
      
      final firstItem = json.first as Map<String, dynamic>;
      if (firstItem.containsKey('result_type')) {
        for (final result in json) {
          final {'result_type': type, 'data': data} = result as Map<String, dynamic>;
          _parseAndAssignResults(type as String, data);
        }
      } else {
        _parseAndAssignResults(firstItem['type'] as String, json);
      }
    } else if (json is Map<String, dynamic>) {
      for (final MapEntry(:key, :value) in json.entries) {
        _parseAndAssignResults(key, value);
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

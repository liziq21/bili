import 'dart:convert';
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
    List<NetworkArticleSearchResult> article,
    List<NetworkBiliUserSearchResult> biliUser,
    List<NetworkMediaBangumiSearchResult> mediaBangumi,
    List<NetworkMediaFtSearchResult> mediaFt,
    List<NetworkLiveRoomSearchResult> liveRoom,
    List<NetworkLiveUserSearchResult> liveUser,
    List<NetworkVideoSearchResult> video,
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
      
      final resultsWhereType = (results as Iterable).whereType<Map<String, Object?>>();
      if (resultsWhereType.isEmpty) {
        return;
      }
      
      switch (SearchResultType.parse(type)) {
        case .article:
          articleResults = resultsWhereType
            .map(NetworkArticleSearchResult.fromJson).toList();
        case .biliUser:
          biliUserResults = resultsWhereType
            .map(NetworkBiliUserSearchResult.fromJson).toList();
        case .mediaBangumi:
          mediaBangumiResults = resultsWhereType
            .map(NetworkMediaBangumiSearchResult.fromJson).toList();
        case .mediaFt:
          mediaFtResults = resultsWhereType
            .map(NetworkMediaFtSearchResult.fromJson).toList();
        case .liveRoom:
          liveRoomResults = resultsWhereType
            .map(NetworkLiveRoomSearchResult.fromJson).toList();
        case .liveUser:
          liveUserResults = resultsWhereType
            .map(NetworkLiveUserSearchResult.fromJson).toList();
        case .video:
          videoResults = resultsWhereType
            .map(NetworkVideoSearchResult.fromJson).toList();
        default:
      }
    }

    if (json is Map<String, dynamic>) {
      for (final MapEntry(:key, :value) in json.entries) {
        _parseAndAssignResults(key, value);
      }
    } else if (json is List && json.isNotEmpty) {
      final list = json.whereType<Map<String, dynamic>>();
      if (list.first.containsKey('result_type')) {
        for (final {'result_type': type, 'data': data} in list) {
          _parseAndAssignResults(type, data);
        }
      } else {
        _parseAndAssignResults(list.first['type'] as String, list);
      }
    } else {
      return const NetworkSearchResultWrapper();
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

import 'package:json_annotation/json_annotation.dart';

import '../common/html_title.dart';

part 'network_live_user_search_result.g.dart';

@JsonSerializable(fieldRename: .snake, createToJson: false)
class const NetworkLiveUserSearchResult({
  required final int area,
  required final int areaV2Id,
  required final int attentions,
  required final String cateName,
  required final int id,
  required final bool isLive,
  required final int liveStatus,
  required final String liveTime,
  required final int rankIndex,
  required final int rankOffset,
  required final int roomid,
  required final String tags,
  required final String uface,
  required final int uid,
  required final HtmlTitle uname,
}) {
  factory NetworkLiveUserSearchResult.fromJson(Map<String, dynamic> json) =>
      _$NetworkLiveUserSearchResultFromJson(json);
}

// @freezed
// abstract class NetworkLiveUserSearchResult with _$NetworkLiveUserSearchResult {
//   @JsonSerializable(fieldRename: .snake)
//   const factory NetworkLiveUserSearchResult({
//     required int area,
//     required int areaV2Id,
//     required int attentions,
//     required String cateName,
//     required int id,
//     required bool isLive,
//     required int liveStatus,
//     required String liveTime,
//     required int rankIndex,
//     required int rankOffset,
//     required int roomid,
//     required String tags,
//     required String uface,
//     required int uid,
//     required HtmlTitle uname,
//   }) = _NetworkLiveUserSearchResult;
//
//   factory NetworkLiveUserSearchResult.fromJson(Map<String, dynamic> json) =>
//       _$NetworkLiveUserSearchResultFromJson(json);
// }


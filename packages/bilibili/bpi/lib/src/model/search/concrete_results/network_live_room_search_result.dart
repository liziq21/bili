import 'package:json_annotation/json_annotation.dart';

import '../common/html_title.dart';

part 'network_live_room_search_result.g.dart';

@JsonSerializable(fieldRename: .snake, createToJson: false)
class const NetworkLiveRoomSearchResult({
  required final int area,
  required final int attentions,
  required final String cateName,
  required final String cover,
  required final int isLiveRoomInline,
  required final int liveStatus,
  required final String liveTime,
  required final int online,
  required final int rankIndex,
  required final int rankOffset,
  required final int roomid,
  required final int shortId,
  required final int style,
  required final String tags,
  required final HtmlTitle title,
  required final String uface,
  required final int uid,
  required final String uname,
  required final String userCover,
}) {
  factory NetworkLiveRoomSearchResult.fromJson(Map<String, dynamic> json) =>
      _$NetworkLiveRoomSearchResultFromJson(json);
}

// @freezed
// abstract class NetworkLiveRoomSearchResult with _$NetworkLiveRoomSearchResult {
//   @JsonSerializable(fieldRename: .snake)
//   const factory NetworkLiveRoomSearchResult({
//     required int area,
//     required int attentions,
//     required String cateName,
//     required String cover,
//     required int isLiveRoomInline,
//     required int liveStatus,
//     required String liveTime,
//     required int online,
//     required int rankIndex,
//     required int rankOffset,
//     required int roomid,
//     required int shortId,
//     required int style,
//     required String tags,
//     required HtmlTitle title,
//     required String uface,
//     required int uid,
//     required String uname,
//     required String userCover,
//   }) = _NetworkLiveRoomSearchResult;
//
//   factory NetworkLiveRoomSearchResult.fromJson(Map<String, dynamic> json) =>
//       _$NetworkLiveRoomSearchResultFromJson(json);
// }

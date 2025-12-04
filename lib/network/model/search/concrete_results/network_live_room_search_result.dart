import 'package:freezed_annotation/freezed_annotation.dart';
import '../common/html_title.dart';

part 'network_live_room_search_result.freezed.dart';
part 'network_live_room_search_result.g.dart';

@freezed
abstract class NetworkLiveRoomSearchResult with _$NetworkLiveRoomSearchResult {
  @JsonSerializable(fieldRename: .snake)
  const factory NetworkLiveRoomSearchResult({
    required int area,
    required int attentions,
    required String cateName,
    required String cover,
    required int isLiveRoomInline,
    required int liveStatus,
    required String liveTime,
    required int online,
    required int rankIndex,
    required int rankOffset,
    required int roomid,
    required int shortId,
    required int style,
    required String tags,
    required HtmlTitle title,
    required String uface,
    required int uid,
    required String uname,
    required String userCover,
  }) = _NetworkLiveRoomSearchResult;

  factory NetworkLiveRoomSearchResult.fromJson(Map<String, dynamic> json) =>
      _$NetworkLiveRoomSearchResultFromJson(json);
}
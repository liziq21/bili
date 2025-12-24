import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_live_room_search_result.freezed.dart';

@freezed
abstract class LiveRoomSearchResult with _$LiveRoomSearchResult {
  const factory LiveRoomSearchResult({
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
    required String title,
    required String uface,
    required int uid,
    required String uname,
    required String userCover,
  }) = _LiveRoomSearchResult;
}

extension NetworkLiveRoomSearchResultX on NetworkLiveRoomSearchResult {
  LiveRoomSearchResult asModel() => LiveRoomSearchResult(
    area: area,
    attentions: attentions,
    cateName: cateName,
    cover: cover,
    isLiveRoomInline: isLiveRoomInline,
    liveStatus: liveStatus,
    liveTime: liveTime,
    online: online,
    rankIndex: rankIndex,
    rankOffset: rankOffset,
    roomid: roomid,
    shortId: shortId,
    style: style,
    tags: tags,
    title: title,
    uface: uface,
    uid: uid,
    uname: uname.parsedTitle(),
    userCover: userCover,
  );
}
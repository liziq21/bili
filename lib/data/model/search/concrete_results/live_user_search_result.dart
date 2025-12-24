import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_live_user_search_result.freezed.dart';

@freezed
abstract class LiveUserSearchResult with _$LiveUserSearchResult {
  const factory LiveUserSearchResult({
    required int area,
    required int areaV2Id,
    required int attentions,
    required String cateName,
    required int id,
    required bool isLive,
    required int liveStatus,
    required String liveTime,
    required int rankIndex,
    required int rankOffset,
    required int roomid,
    required String tags,
    required String uface,
    required int uid,
    required String uname,
  }) = _LiveUserSearchResult;
}

extension NetworkLiveUserSearchResultX on NetworkLiveUserSearchResult {
  LiveUserSearchResult asModel() => LiveUserSearchResult(
    area: area,
    areaV2Id: areaV2Id,
    attentions: attentions,
    cateName: cateName,
    id: id,
    isLive: isLive,
    liveStatus: liveStatus,
    liveTime: liveTime,
    rankIndex: rankIndex,
    rankOffset: rankOffset,
    roomid: roomid,
    tags: tags,
    uface: uface,
    uid: uid,
    uname: uname.parsedTitle(),
  );
}
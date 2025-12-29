import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

import '../../../network/model/search/concrete_results/network_live_room_search_result.dart';

part 'live_room.freezed.dart';

@freezed
abstract class LiveRoom with _$LiveRoom {
  const factory LiveRoom({
    required int id,
    required String title,
    required String coverUrl,
    required bool isLive,
    required String cateName,
    required int uid,
    required String uname,
  }) = _LiveRoom;
}

extension NetworkLiveRoomSearchResultX on NetworkLiveRoomSearchResult {
  LiveRoom asModel() => LiveRoom(
    id: id,
    title: title.parsedTitle(),
    coverUrl: 'https:$cover',
    isLive: liveStatus == 1,
    cateName: cateName,
    uid: uid,
    uname: uname,
  );
}
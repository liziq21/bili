import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

import '../../../network/model/search/concrete_results/network_bili_user_search_result.dart';
import '../../../network/model/search/concrete_results/network_live_user_search_result.dart';

part 'creator_profile.freezed.dart';

@freezed
abstract class CreatorProfile with _$CreatorProfile {
  const factory CreatorProfile({
    required String id,
    required String name,
    required String thumbnailUrl,
    required bool isLive,
    required int roomId,
    int? subscribers,
    int? videos,
  }) = _CreatorProfile;
}

extension NetworkBiliUserSearchResultX on NetworkBiliUserSearchResult {
  CreatorProfile asModel() => CreatorProfile(
    id: mid,
    name: uname,
    thumbnailUrl: 'https:$upic',
    isLive: isLive == 1,
    roomId: roomId,
    subscribers: fans,
    videos: videos,
  );
}

extension NetworkLiveUserSearchResultX on NetworkLiveUserSearchResult {
  CreatorProfile asModel() => CreatorProfile(
    id: uid,
    name: uname.parsedTitle(),
    thumbnailUrl: 'https:$uface',
    isLive: isLive,
    roomId: roomid,
  );
}
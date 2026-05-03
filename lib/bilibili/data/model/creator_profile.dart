import '../../network/model/search/concrete_results/network_bili_user_search_result.dart';
import '../../network/model/search/concrete_results/network_live_user_search_result.dart';
import '../../../data/model/creator_profile.dart';

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

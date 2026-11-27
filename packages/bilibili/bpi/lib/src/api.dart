final class SearchApi {
  static const host = 's.search.bilibili.com';
  static const base = 'https://$host';

  static const suggest = '$base${SearchApiPath.suggest}';
}

final class SearchApiPath {
  static const suggest = '/main/suggest';
}

final class Api {
  static const host = 'api.bilibili.com';
  static const base = 'https://$host';

  static const search = '$base${ApiPath.search}';
  static const searchByType = '$base${ApiPath.searchByType}';
}

final class ApiPath {
  static const search = '/x/web-interface/search/all/v2';
  static const searchByType = '/x/web-interface/search/type';
  static const String videoIntro = '/x/web-interface/view';
  static const String videoRelation = '/x/web-interface/archive/relation';
  static const String relatedList = '/x/web-interface/archive/related';
  static const String replyList = '/x/v2/reply';
  static const String replyListMain = '/x/v2/reply/main';
  static const String replyReplyList = '/x/v2/reply/reply';
  static const String popular = '/x/web-interface/popular';
  static const String ranking = '/x/web-interface/ranking/v2';
  static const String playerV2 = '/x/player/v2';
  static const String userCard = '/x/web-interface/card';
  static const String userArticles = '/x/space/article';
  static const String videoParts = '/x/player/pagelist';
  static const String videoSnapshot = '/x/player/videoshot';
  static const String videoTags = '/x/web-interface/view/detail/tag';
  static const String seriesArchives = '/x/series/archives';
  static const String bangumiSeason = '/pgc/view/web/season';
  static const String bangumiPlayUrl = '/pgc/player/web/playurl';
  static const String bangumiPlayUrlV2 = '/pgc/player/web/v2/playurl';
}

final class DanmakuApi {
  static const host = 'comment.bilibili.com';

  static const base = 'https://$host';

  static String comment(int cid) => '$base/$cid.xml';
}

final class WbiApiPath {
  static const String searchByType = '/x/web-interface/wbi/search/type';
  static const String searchAll = '/x/web-interface/wbi/search/all/v2';
  static const String playUrl = '/x/player/wbi/playurl';
  static const String playlistContent =
      '/x/polymer/web-space/seasons_archives_list';
  static const String userPlaylists =
      '/x/polymer/web-space/seasons_series_list';
  static const String userVideos = '/x/space/wbi/arc/search';
  static const String homeFeed = '/x/web-interface/wbi/index/top/feed/rcmd';
}

final class LiveApi {
  static const host = 'api.live.bilibili.com';
  static const base = 'https://$host';

  static const roomDetail = '$base${LiveApiPath.roomDetail}';
  static const roomPlayInfo = '$base${LiveApiPath.roomPlayInfo}';
  static const danmuInfo = '$base${LiveApiPath.danmuInfo}';
  static const roomBaseInfo = '$base${LiveApiPath.roomBaseInfo}';
  static const statusByUids = '$base${LiveApiPath.statusByUids}';
  static const recommendedRooms = '$base${LiveApiPath.recommendedRooms}';
}

final class LiveApiPath {
  static const String roomDetail = '/xlive/web-room/v1/index/getH5InfoByRoom';
  static const String roomPlayInfo = '/xlive/web-room/v2/index/getRoomPlayInfo';
  static const String danmuInfo = '/xlive/web-room/v1/index/getDanmuInfo';
  static const String roomBaseInfo = '/xlive/web-room/v1/index/getRoomBaseInfo';
  static const String statusByUids = '/room/v1/Room/get_status_info_by_uids';
  static const String recommendedRooms = '/room/v1/room/get_user_recommend';
}

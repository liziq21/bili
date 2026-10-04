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
}

final class WbiApiPath {
  static const String searchByType = '/x/web-interface/wbi/search/type';
  static const String searchAll = '/x/web-interface/wbi/search/all/v2';
  static const String playUrl = '/x/player/wbi/playurl';
}

final class LiveApi {
  static const host = 'api.live.bilibili.com';
  static const base = 'https://$host';

  static const roomDetail = '$base${LiveApiPath.roomDetail}';
  static const roomPlayInfo = '$base${LiveApiPath.roomPlayInfo}';
}

final class LiveApiPath {
  static const String roomDetail = '/xlive/web-room/v1/index/getH5InfoByRoom';
  static const String roomPlayInfo = '/xlive/web-room/v2/index/getRoomPlayInfo';
}

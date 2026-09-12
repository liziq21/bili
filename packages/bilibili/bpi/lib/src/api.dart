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
}

final class WbiApiPath {
  static const String searchByType = '/x/web-interface/wbi/search/type';
  static const String searchAll = '/x/web-interface/wbi/search/all/v2';
  static const String playUrl = '/x/player/wbi/playurl';
}

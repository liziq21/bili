import '../../error/bpi_exception.dart';
import '../bili_json_readers.dart';

/// 首页推荐 (`/x/web-interface/wbi/index/top/feed/rcmd`)。
final class NetworkBiliHomeFeed {
  const NetworkBiliHomeFeed({
    required this.code,
    required this.message,
    required this.ttl,
    required this.items,
  });

  factory NetworkBiliHomeFeed.fromJson(Map<String, dynamic> json) {
    final code = biliReadInt(json['code']);
    if (code == null) {
      throw const BpiSerializationException(
        'Bilibili home feed response is missing a numeric code.',
      );
    }
    if (code != 0) {
      throw BiliApiException(
        json['message']?.toString() ?? 'Bilibili home feed request failed.',
        biliCode: code,
      );
    }

    final rawData = json['data'];
    if (rawData is! Map) {
      throw const BpiSerializationException(
        'Bilibili home feed response is missing an object data field.',
      );
    }

    return NetworkBiliHomeFeed(
      code: code,
      message: json['message']?.toString() ?? '',
      ttl: biliReadInt(json['ttl']) ?? 0,
      items: biliReadObjectList(
        rawData['item'],
        NetworkBiliHomeFeedItem.tryFromJson,
      ),
    );
  }

  final int code;
  final String message;
  final int ttl;
  final List<NetworkBiliHomeFeedItem> items;
}

/// 首页条目。`goto` 区分视频 (`av`)、直播 (`live`) 和广告等类型；只有视频条目
/// 带 `bvid`，因此缺少标识的条目被丢弃。
final class NetworkBiliHomeFeedItem {
  const NetworkBiliHomeFeedItem({
    required this.goto,
    this.id,
    this.bvid,
    this.cid,
    this.uri,
    this.pic,
    this.title,
    this.duration,
    this.pubdate,
    this.owner,
    this.stat,
  });

  static NetworkBiliHomeFeedItem? tryFromJson(Map<dynamic, dynamic> json) {
    final bvid = biliReadString(json['bvid']);
    final id = biliReadStringId(json['id']);
    if (bvid == null && id == null) {
      return null;
    }
    return NetworkBiliHomeFeedItem(
      goto: biliReadString(json['goto']) ?? '',
      id: id,
      bvid: bvid,
      cid: biliReadInt(json['cid']),
      uri: biliReadString(json['uri']),
      pic: biliReadString(json['pic']),
      title: biliReadString(json['title']),
      duration: biliReadInt(json['duration']),
      pubdate: biliReadInt(json['pubdate']),
      owner: biliReadObject(
        json['owner'],
        NetworkBiliHomeFeedOwner.tryFromJson,
      ),
      stat: biliReadObject(json['stat'], NetworkBiliHomeFeedStat.tryFromJson),
    );
  }

  final String goto;
  final String? id;
  final String? bvid;
  final int? cid;
  final String? uri;
  final String? pic;
  final String? title;
  final int? duration;
  final int? pubdate;
  final NetworkBiliHomeFeedOwner? owner;
  final NetworkBiliHomeFeedStat? stat;
}

final class NetworkBiliHomeFeedOwner {
  const NetworkBiliHomeFeedOwner({this.mid, this.name, this.face});

  static NetworkBiliHomeFeedOwner? tryFromJson(Map<dynamic, dynamic> json) {
    final mid = biliReadInt(json['mid']);
    final name = biliReadString(json['name']);
    final face = biliReadString(json['face']);
    if (mid == null && name == null && face == null) {
      return null;
    }
    return NetworkBiliHomeFeedOwner(mid: mid, name: name, face: face);
  }

  final int? mid;
  final String? name;
  final String? face;
}

final class NetworkBiliHomeFeedStat {
  const NetworkBiliHomeFeedStat({this.view, this.like, this.danmaku});

  static NetworkBiliHomeFeedStat? tryFromJson(Map<dynamic, dynamic> json) {
    final stat = NetworkBiliHomeFeedStat(
      view: biliReadInt(json['view']),
      like: biliReadInt(json['like']),
      danmaku: biliReadInt(json['danmaku']),
    );
    if (stat.view == null && stat.like == null && stat.danmaku == null) {
      return null;
    }
    return stat;
  }

  final int? view;
  final int? like;
  final int? danmaku;
}

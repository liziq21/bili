import '../../error/bpi_exception.dart';

final class NetworkBiliPopularResponse {
  const NetworkBiliPopularResponse({
    required this.code,
    required this.message,
    required this.ttl,
    required this.data,
  });

  factory NetworkBiliPopularResponse.fromJson(Map<String, dynamic> json) {
    final code = _readInt(json['code']);
    if (code == null) {
      throw const BpiSerializationException(
        'Bilibili popular response is missing a numeric code.',
      );
    }
    if (code != 0) {
      throw BiliApiException(
        json['message']?.toString() ?? 'Bilibili popular request failed.',
        biliCode: code,
      );
    }

    final ttl = _readInt(json['ttl']);
    if (ttl == null) {
      throw const BpiSerializationException(
        'Bilibili popular response is missing a numeric ttl.',
      );
    }
    final rawData = json['data'];
    if (rawData is! Map) {
      throw const BpiSerializationException(
        'Bilibili popular response is missing an object data field.',
      );
    }

    return NetworkBiliPopularResponse(
      code: code,
      message: json['message']?.toString() ?? '',
      ttl: ttl,
      data: NetworkBiliPopularData.fromJson(Map<String, dynamic>.from(rawData)),
    );
  }

  final int code;
  final String message;
  final int ttl;
  final NetworkBiliPopularData data;
}

final class NetworkBiliPopularData {
  const NetworkBiliPopularData({required this.list, required this.noMore});

  factory NetworkBiliPopularData.fromJson(Map<String, dynamic> json) {
    final rawList = json['list'];
    if (rawList is! List) {
      throw const BpiSerializationException(
        'Bilibili popular data.list is not a list.',
      );
    }

    return NetworkBiliPopularData(
      list: rawList
          .whereType<Map>()
          .map(NetworkBiliPopularVideo.tryFromJson)
          .nonNulls
          .toList(growable: false),
      noMore: json['no_more'] == true,
    );
  }

  final List<NetworkBiliPopularVideo> list;
  final bool noMore;
}

final class NetworkBiliPopularVideo {
  const NetworkBiliPopularVideo({
    required this.aid,
    required this.bvid,
    this.title,
    this.pic,
    this.pubdate,
    this.duration,
    this.tname,
    this.owner,
    this.stat,
  });

  static NetworkBiliPopularVideo? tryFromJson(Map<dynamic, dynamic> json) {
    final aid = _readInt(json['aid']);
    final bvid = json['bvid']?.toString();
    if (aid == null || bvid == null || bvid.isEmpty) {
      return null;
    }

    return NetworkBiliPopularVideo(
      aid: aid,
      bvid: bvid,
      title: _readString(json['title']),
      pic: _readString(json['pic']),
      pubdate: _readInt(json['pubdate']),
      duration: _readInt(json['duration']),
      tname: _readString(json['tname']),
      owner: _readObject(json['owner'], NetworkBiliPopularOwner.tryFromJson),
      stat: _readObject(json['stat'], NetworkBiliPopularStat.tryFromJson),
    );
  }

  final int aid;
  final String bvid;
  final String? title;
  final String? pic;
  final int? pubdate;
  final int? duration;
  final String? tname;
  final NetworkBiliPopularOwner? owner;
  final NetworkBiliPopularStat? stat;
}

final class NetworkBiliPopularOwner {
  const NetworkBiliPopularOwner({this.mid, this.name, this.face});

  static NetworkBiliPopularOwner? tryFromJson(Map<dynamic, dynamic> json) {
    final mid = _readInt(json['mid']);
    final name = _readString(json['name']);
    final face = _readString(json['face']);
    if (mid == null && name == null && face == null) {
      return null;
    }
    return NetworkBiliPopularOwner(mid: mid, name: name, face: face);
  }

  final int? mid;
  final String? name;
  final String? face;
}

final class NetworkBiliPopularStat {
  const NetworkBiliPopularStat({
    this.view,
    this.danmaku,
    this.reply,
    this.favorite,
    this.coin,
    this.share,
    this.like,
  });

  static NetworkBiliPopularStat? tryFromJson(Map<dynamic, dynamic> json) {
    final stat = NetworkBiliPopularStat(
      view: _readInt(json['view']),
      danmaku: _readInt(json['danmaku']),
      reply: _readInt(json['reply']),
      favorite: _readInt(json['favorite']),
      coin: _readInt(json['coin']),
      share: _readInt(json['share']),
      like: _readInt(json['like']),
    );
    if (stat.view == null &&
        stat.danmaku == null &&
        stat.reply == null &&
        stat.favorite == null &&
        stat.coin == null &&
        stat.share == null &&
        stat.like == null) {
      return null;
    }
    return stat;
  }

  final int? view;
  final int? danmaku;
  final int? reply;
  final int? favorite;
  final int? coin;
  final int? share;
  final int? like;
}

int? _readInt(Object? value) {
  return switch (value) {
    final int value => value,
    final num value => value.toInt(),
    final String value => int.tryParse(value),
    _ => null,
  };
}

String? _readString(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return value;
}

T? _readObject<T>(
  Object? value,
  T? Function(Map<dynamic, dynamic> json) parse,
) {
  if (value is! Map) {
    return null;
  }
  return parse(value);
}

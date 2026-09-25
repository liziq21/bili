import '../../error/bpi_exception.dart';

final class NetworkBiliRankingResponse {
  const NetworkBiliRankingResponse({
    required this.code,
    required this.message,
    required this.ttl,
    required this.data,
  });

  factory NetworkBiliRankingResponse.fromJson(Map<String, dynamic> json) {
    final code = _readInt(json['code']);
    if (code == null) {
      throw const BpiSerializationException(
        'Bilibili ranking response is missing a numeric code.',
      );
    }
    if (code != 0) {
      throw BiliApiException(
        json['message']?.toString() ?? 'Bilibili ranking request failed.',
        biliCode: code,
      );
    }

    final ttl = _readInt(json['ttl']);
    if (ttl == null) {
      throw const BpiSerializationException(
        'Bilibili ranking response is missing a numeric ttl.',
      );
    }
    final rawData = json['data'];
    if (rawData is! Map) {
      throw const BpiSerializationException(
        'Bilibili ranking response is missing an object data field.',
      );
    }

    return NetworkBiliRankingResponse(
      code: code,
      message: json['message']?.toString() ?? '',
      ttl: ttl,
      data: NetworkBiliRankingData.fromJson(Map<String, dynamic>.from(rawData)),
    );
  }

  final int code;
  final String message;
  final int ttl;
  final NetworkBiliRankingData data;
}

final class NetworkBiliRankingData {
  const NetworkBiliRankingData({required this.list, this.note});

  factory NetworkBiliRankingData.fromJson(Map<String, dynamic> json) {
    final rawList = json['list'];
    if (rawList is! List) {
      throw const BpiSerializationException(
        'Bilibili ranking data.list is not a list.',
      );
    }

    return NetworkBiliRankingData(
      list: rawList
          .whereType<Map>()
          .map(NetworkBiliRankingVideo.tryFromJson)
          .nonNulls
          .toList(growable: false),
      note: _readString(json['note']),
    );
  }

  final List<NetworkBiliRankingVideo> list;
  final String? note;
}

final class NetworkBiliRankingVideo {
  const NetworkBiliRankingVideo({
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

  static NetworkBiliRankingVideo? tryFromJson(Map<dynamic, dynamic> json) {
    final aid = _readInt(json['aid']);
    final bvidRaw = json['bvid'];
    final bvid = bvidRaw is String ? bvidRaw : null;
    if (aid == null || bvid == null || bvid.isEmpty) {
      return null;
    }

    return NetworkBiliRankingVideo(
      aid: aid,
      bvid: bvid,
      title: _readString(json['title']),
      pic: _readString(json['pic']),
      pubdate: _readInt(json['pubdate']),
      duration: _readInt(json['duration']),
      tname: _readString(json['tname']),
      owner: _readObject(json['owner'], NetworkBiliRankingOwner.tryFromJson),
      stat: _readObject(json['stat'], NetworkBiliRankingStat.tryFromJson),
    );
  }

  final int aid;
  final String bvid;
  final String? title;
  final String? pic;
  final int? pubdate;
  final int? duration;
  final String? tname;
  final NetworkBiliRankingOwner? owner;
  final NetworkBiliRankingStat? stat;
}

final class NetworkBiliRankingOwner {
  const NetworkBiliRankingOwner({this.mid, this.name, this.face});

  static NetworkBiliRankingOwner? tryFromJson(Map<dynamic, dynamic> json) {
    final mid = _readInt(json['mid']);
    final name = _readString(json['name']);
    final face = _readString(json['face']);
    if (mid == null && name == null && face == null) {
      return null;
    }
    return NetworkBiliRankingOwner(mid: mid, name: name, face: face);
  }

  final int? mid;
  final String? name;
  final String? face;
}

final class NetworkBiliRankingStat {
  const NetworkBiliRankingStat({
    this.view,
    this.danmaku,
    this.reply,
    this.favorite,
    this.coin,
    this.share,
    this.like,
    this.nowRank,
    this.hisRank,
  });

  static NetworkBiliRankingStat? tryFromJson(Map<dynamic, dynamic> json) {
    final stat = NetworkBiliRankingStat(
      view: _readInt(json['view']),
      danmaku: _readInt(json['danmaku']),
      reply: _readInt(json['reply']),
      favorite: _readInt(json['favorite']),
      coin: _readInt(json['coin']),
      share: _readInt(json['share']),
      like: _readInt(json['like']),
      nowRank: _readInt(json['now_rank']),
      hisRank: _readInt(json['his_rank']),
    );
    if (stat.view == null &&
        stat.danmaku == null &&
        stat.reply == null &&
        stat.favorite == null &&
        stat.coin == null &&
        stat.share == null &&
        stat.like == null &&
        stat.nowRank == null &&
        stat.hisRank == null) {
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
  final int? nowRank;
  final int? hisRank;
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

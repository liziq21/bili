import 'package:meta/meta.dart';

import '../../error/bpi_exception.dart';
import '../bili_json_readers.dart';

/// 用户系列（series）视频列表 (`/x/series/archives`)。
///
/// 合集使用 `seasons_archives_list`，系列使用本端点；两者分页字段不同。
@immutable
final class NetworkBiliSeriesArchives {
  const NetworkBiliSeriesArchives({
    required this.code,
    required this.message,
    required this.ttl,
    required this.archives,
    this.aids = const [],
    this.page,
  });

  factory NetworkBiliSeriesArchives.fromJson(Map<String, dynamic> json) {
    final code = biliReadInt(json['code']);
    if (code == null) {
      throw const BpiSerializationException(
        'Bilibili series archives response is missing a numeric code.',
      );
    }
    if (code != 0) {
      throw BiliApiException(
        json['message']?.toString() ??
            'Bilibili series archives request failed.',
        biliCode: code,
      );
    }

    final rawData = json['data'];
    if (rawData is! Map) {
      throw const BpiSerializationException(
        'Bilibili series archives response is missing an object data field.',
      );
    }

    return NetworkBiliSeriesArchives(
      code: code,
      message: json['message']?.toString() ?? '',
      ttl: biliReadInt(json['ttl']) ?? 0,
      aids: biliReadIntList(rawData['aids']),
      archives: biliReadObjectList(
        rawData['archives'],
        NetworkBiliSeriesArchive.tryFromJson,
      ),
      page: biliReadObject(rawData['page'], NetworkBiliSeriesPage.tryFromJson),
    );
  }

  final int code;
  final String message;
  final int ttl;
  final List<int> aids;
  final List<NetworkBiliSeriesArchive> archives;
  final NetworkBiliSeriesPage? page;
}

@immutable
final class NetworkBiliSeriesArchive {
  const NetworkBiliSeriesArchive({
    required this.aid,
    required this.bvid,
    this.title,
    this.pic,
    this.pubdate,
    this.ctime,
    this.duration,
    this.stat,
  });

  static NetworkBiliSeriesArchive? tryFromJson(Map<dynamic, dynamic> json) {
    final aid = biliReadInt(json['aid']);
    final bvid = biliReadString(json['bvid']);
    if (aid == null || bvid == null) {
      return null;
    }
    return NetworkBiliSeriesArchive(
      aid: aid,
      bvid: bvid,
      title: biliReadString(json['title']),
      pic: biliReadString(json['pic']),
      pubdate: biliReadInt(json['pubdate']),
      ctime: biliReadInt(json['ctime']),
      duration: biliReadInt(json['duration']),
      stat: biliReadObject(
        json['stat'],
        NetworkBiliSeriesArchiveStat.tryFromJson,
      ),
    );
  }

  final int aid;
  final String bvid;
  final String? title;
  final String? pic;
  final int? pubdate;
  final int? ctime;
  final int? duration;
  final NetworkBiliSeriesArchiveStat? stat;
}

@immutable
final class NetworkBiliSeriesArchiveStat {
  const NetworkBiliSeriesArchiveStat({this.view});

  static NetworkBiliSeriesArchiveStat? tryFromJson(Map<dynamic, dynamic> json) {
    final view = biliReadInt(json['view']);
    if (view == null) {
      return null;
    }
    return NetworkBiliSeriesArchiveStat(view: view);
  }

  final int? view;
}

@immutable
final class NetworkBiliSeriesPage {
  const NetworkBiliSeriesPage({this.num, this.size, this.total});

  static NetworkBiliSeriesPage? tryFromJson(Map<dynamic, dynamic> json) {
    final page = NetworkBiliSeriesPage(
      num: biliReadInt(json['num']),
      size: biliReadInt(json['size']),
      total: biliReadInt(json['total']),
    );
    if (page.num == null && page.size == null && page.total == null) {
      return null;
    }
    return page;
  }

  final int? num;
  final int? size;
  final int? total;
}

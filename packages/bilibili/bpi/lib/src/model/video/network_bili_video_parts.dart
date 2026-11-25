import 'package:meta/meta.dart';

import '../../error/bpi_exception.dart';
import '../bili_json_readers.dart';

/// 视频分P列表 (`/x/player/pagelist`)。
@immutable
final class NetworkBiliVideoParts {
  const NetworkBiliVideoParts({
    required this.code,
    required this.message,
    required this.ttl,
    required this.parts,
  });

  factory NetworkBiliVideoParts.fromJson(Map<String, dynamic> json) {
    final code = biliReadInt(json['code']);
    if (code == null) {
      throw const BpiSerializationException(
        'Bilibili video parts response is missing a numeric code.',
      );
    }
    if (code != 0) {
      throw BiliApiException(
        json['message']?.toString() ?? 'Bilibili video parts request failed.',
        biliCode: code,
      );
    }

    final rawData = json['data'];
    if (rawData is! List) {
      throw const BpiSerializationException(
        'Bilibili video parts response is missing a list data field.',
      );
    }

    return NetworkBiliVideoParts(
      code: code,
      message: json['message']?.toString() ?? '',
      ttl: biliReadInt(json['ttl']) ?? 0,
      parts: biliReadObjectList(rawData, NetworkBiliVideoPart.tryFromJson),
    );
  }

  final int code;
  final String message;
  final int ttl;
  final List<NetworkBiliVideoPart> parts;
}

@immutable
final class NetworkBiliVideoPart {
  const NetworkBiliVideoPart({
    required this.cid,
    required this.page,
    this.part,
    this.duration,
    this.width,
    this.height,
    this.ctime,
  });

  static NetworkBiliVideoPart? tryFromJson(Map<dynamic, dynamic> json) {
    final cid = biliReadInt(json['cid']);
    if (cid == null) {
      return null;
    }
    final dimension = json['dimension'];
    return NetworkBiliVideoPart(
      cid: cid,
      page: biliReadInt(json['page']) ?? 0,
      part: biliReadString(json['part']),
      duration: biliReadInt(json['duration']),
      width: dimension is Map ? biliReadInt(dimension['width']) : null,
      height: dimension is Map ? biliReadInt(dimension['height']) : null,
      ctime: biliReadInt(json['ctime']),
    );
  }

  final int cid;
  final int page;
  final String? part;
  final int? duration;
  final int? width;
  final int? height;
  final int? ctime;
}

import 'package:meta/meta.dart';

import '../../error/bpi_exception.dart';
import '../bili_json_readers.dart';

/// 视频进度条预览图 (`/x/player/videoshot`)。
@immutable
final class NetworkBiliVideoSnapshot {
  const NetworkBiliVideoSnapshot({
    required this.code,
    required this.message,
    required this.ttl,
    this.pvdata,
    this.imgXLen,
    this.imgYLen,
    this.imgXSize,
    this.imgYSize,
    this.images = const [],
    this.index = const [],
  });

  factory NetworkBiliVideoSnapshot.fromJson(Map<String, dynamic> json) {
    final code = biliReadInt(json['code']);
    if (code == null) {
      throw const BpiSerializationException(
        'Bilibili video snapshot response is missing a numeric code.',
      );
    }
    if (code != 0) {
      throw BiliApiException(
        json['message']?.toString() ??
            'Bilibili video snapshot request failed.',
        biliCode: code,
      );
    }

    final rawData = json['data'];
    if (rawData is! Map) {
      throw const BpiSerializationException(
        'Bilibili video snapshot response is missing an object data field.',
      );
    }

    return NetworkBiliVideoSnapshot(
      code: code,
      message: json['message']?.toString() ?? '',
      ttl: biliReadInt(json['ttl']) ?? 0,
      pvdata: biliReadString(rawData['pvdata']),
      imgXLen: biliReadInt(rawData['img_x_len']),
      imgYLen: biliReadInt(rawData['img_y_len']),
      imgXSize: biliReadInt(rawData['img_x_size']),
      imgYSize: biliReadInt(rawData['img_y_size']),
      images: biliReadStringList(rawData['image']),
      index: biliReadIntList(rawData['index']),
    );
  }

  final int code;
  final String message;
  final int ttl;
  final String? pvdata;
  final int? imgXLen;
  final int? imgYLen;
  final int? imgXSize;
  final int? imgYSize;
  final List<String> images;
  final List<int> index;
}

import '../../error/bpi_exception.dart';
import '../bili_json_readers.dart';

/// 视频标签 (`/x/web-interface/view/detail/tag`)。
final class NetworkBiliVideoTags {
  const NetworkBiliVideoTags({
    required this.code,
    required this.message,
    required this.ttl,
    required this.tags,
  });

  factory NetworkBiliVideoTags.fromJson(Map<String, dynamic> json) {
    final code = biliReadInt(json['code']);
    if (code == null) {
      throw const BpiSerializationException(
        'Bilibili video tags response is missing a numeric code.',
      );
    }
    if (code != 0) {
      throw BiliApiException(
        json['message']?.toString() ?? 'Bilibili video tags request failed.',
        biliCode: code,
      );
    }

    final rawData = json['data'];
    if (rawData is! List) {
      throw const BpiSerializationException(
        'Bilibili video tags response is missing a list data field.',
      );
    }

    return NetworkBiliVideoTags(
      code: code,
      message: json['message']?.toString() ?? '',
      ttl: biliReadInt(json['ttl']) ?? 0,
      tags: biliReadObjectList(rawData, NetworkBiliVideoTag.tryFromJson),
    );
  }

  final int code;
  final String message;
  final int ttl;
  final List<NetworkBiliVideoTag> tags;
}

final class NetworkBiliVideoTag {
  const NetworkBiliVideoTag({
    required this.tagId,
    required this.tagName,
    this.tagType,
    this.jumpUrl,
  });

  static NetworkBiliVideoTag? tryFromJson(Map<dynamic, dynamic> json) {
    final tagId = biliReadInt(json['tag_id']);
    final tagName = biliReadString(json['tag_name']);
    if (tagId == null || tagName == null) {
      return null;
    }
    return NetworkBiliVideoTag(
      tagId: tagId,
      tagName: tagName,
      tagType: biliReadString(json['tag_type']),
      jumpUrl: biliReadString(json['jump_url']),
    );
  }

  final int tagId;
  final String tagName;
  final String? tagType;
  final String? jumpUrl;
}

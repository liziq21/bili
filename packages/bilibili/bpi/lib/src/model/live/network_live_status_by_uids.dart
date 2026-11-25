import '../../error/bpi_exception.dart';
import '../bili_json_readers.dart';

/// 按 UP 主批量查询直播状态 (`/room/v1/Room/get_status_info_by_uids`)。
final class NetworkLiveStatusByUids {
  const NetworkLiveStatusByUids({
    required this.code,
    required this.message,
    required this.statuses,
  });

  factory NetworkLiveStatusByUids.fromJson(Map<String, dynamic> json) {
    final code = biliReadInt(json['code']);
    if (code == null) {
      throw const BpiSerializationException(
        'Bilibili live status response is missing a numeric code.',
      );
    }
    if (code != 0) {
      throw BiliApiException(
        json['message']?.toString() ??
            json['msg']?.toString() ??
            'Bilibili live status request failed.',
        biliCode: code,
      );
    }

    final rawData = json['data'];
    final statuses = <int, NetworkLiveUserStatus>{};
    if (rawData is Map) {
      for (final entry in rawData.entries) {
        final status = biliReadObject(
          entry.value,
          NetworkLiveUserStatus.tryFromJson,
        );
        if (status == null) continue;
        statuses[status.uid] = status;
      }
    }

    return NetworkLiveStatusByUids(
      code: code,
      message: json['message']?.toString() ?? json['msg']?.toString() ?? '',
      statuses: Map.unmodifiable(statuses),
    );
  }

  final int code;
  final String message;
  final Map<int, NetworkLiveUserStatus> statuses;
}

final class NetworkLiveUserStatus {
  const NetworkLiveUserStatus({
    required this.uid,
    this.roomId,
    this.title,
    this.uname,
    this.face,
    this.cover,
    this.online,
    this.liveStatus,
    this.liveTime,
    this.areaName,
    this.parentAreaName,
    this.tags,
  });

  static NetworkLiveUserStatus? tryFromJson(Map<dynamic, dynamic> json) {
    final uid = biliReadInt(json['uid']);
    if (uid == null) {
      return null;
    }
    return NetworkLiveUserStatus(
      uid: uid,
      roomId: biliReadInt(json['room_id']),
      title: biliReadString(json['title']),
      uname: biliReadString(json['uname']),
      face: biliReadString(json['face']),
      cover: biliReadString(json['cover_from_user']),
      online: biliReadInt(json['online']),
      liveStatus: biliReadInt(json['live_status']),
      liveTime: biliReadInt(json['live_time']),
      areaName: biliReadString(json['area_name']),
      parentAreaName: biliReadString(json['area_v2_parent_name']),
      tags: biliReadString(json['tag_name']),
    );
  }

  final int uid;
  final int? roomId;
  final String? title;
  final String? uname;
  final String? face;
  final String? cover;
  final int? online;
  final int? liveStatus;
  final int? liveTime;
  final String? areaName;
  final String? parentAreaName;
  final String? tags;
}

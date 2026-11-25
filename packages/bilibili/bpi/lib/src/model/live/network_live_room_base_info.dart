import '../../error/bpi_exception.dart';
import '../bili_json_readers.dart';

/// 批量直播间基础信息 (`/xlive/web-room/v1/index/getRoomBaseInfo`)。
final class NetworkLiveRoomBaseInfo {
  const NetworkLiveRoomBaseInfo({
    required this.code,
    required this.message,
    required this.rooms,
  });

  factory NetworkLiveRoomBaseInfo.fromJson(Map<String, dynamic> json) {
    final code = biliReadInt(json['code']);
    if (code == null) {
      throw const BpiSerializationException(
        'Bilibili live room base info response is missing a numeric code.',
      );
    }
    if (code != 0) {
      throw BiliApiException(
        json['message']?.toString() ??
            json['msg']?.toString() ??
            'Bilibili live room base info request failed.',
        biliCode: code,
      );
    }

    final rawData = json['data'];
    if (rawData is! Map) {
      throw const BpiSerializationException(
        'Bilibili live room base info response is missing an object data '
        'field.',
      );
    }

    final byRoomIds = rawData['by_room_ids'];
    final rooms = <int, NetworkLiveRoomBase>{};
    if (byRoomIds is Map) {
      for (final entry in byRoomIds.entries) {
        final room = biliReadObject(
          entry.value,
          NetworkLiveRoomBase.tryFromJson,
        );
        if (room == null) continue;
        rooms[room.roomId] = room;
      }
    }

    return NetworkLiveRoomBaseInfo(
      code: code,
      message: json['message']?.toString() ?? json['msg']?.toString() ?? '',
      rooms: Map.unmodifiable(rooms),
    );
  }

  final int code;
  final String message;
  final Map<int, NetworkLiveRoomBase> rooms;
}

final class NetworkLiveRoomBase {
  const NetworkLiveRoomBase({
    required this.roomId,
    this.uid,
    this.title,
    this.uname,
    this.cover,
    this.liveStatus,
    this.online,
    this.areaId,
    this.areaName,
    this.parentAreaId,
    this.parentAreaName,
    this.liveTime,
    this.shortId,
    this.description,
    this.tags,
  });

  static NetworkLiveRoomBase? tryFromJson(Map<dynamic, dynamic> json) {
    final roomId = biliReadInt(json['room_id']);
    if (roomId == null) {
      return null;
    }
    return NetworkLiveRoomBase(
      roomId: roomId,
      uid: biliReadInt(json['uid']),
      title: biliReadString(json['title']),
      uname: biliReadString(json['uname']),
      cover: biliReadString(json['cover']),
      liveStatus: biliReadInt(json['live_status']),
      online: biliReadInt(json['online']),
      areaId: biliReadInt(json['area_id']),
      areaName: biliReadString(json['area_name']),
      parentAreaId: biliReadInt(json['parent_area_id']),
      parentAreaName: biliReadString(json['parent_area_name']),
      liveTime: biliReadString(json['live_time']),
      shortId: biliReadInt(json['short_id']),
      description: biliReadString(json['description']),
      tags: biliReadString(json['tags']),
    );
  }

  final int roomId;
  final int? uid;
  final String? title;
  final String? uname;
  final String? cover;
  final int? liveStatus;
  final int? online;
  final int? areaId;
  final String? areaName;
  final int? parentAreaId;
  final String? parentAreaName;
  final String? liveTime;
  final int? shortId;
  final String? description;
  final String? tags;
}

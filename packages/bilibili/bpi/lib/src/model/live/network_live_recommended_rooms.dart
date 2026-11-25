import '../../error/bpi_exception.dart';
import '../bili_json_readers.dart';

/// 推荐直播间列表 (`/room/v1/room/get_user_recommend`)。
final class NetworkLiveRecommendedRooms {
  const NetworkLiveRecommendedRooms({
    required this.code,
    required this.message,
    required this.rooms,
  });

  factory NetworkLiveRecommendedRooms.fromJson(Map<String, dynamic> json) {
    final code = biliReadInt(json['code']);
    if (code == null) {
      throw const BpiSerializationException(
        'Bilibili recommended live rooms response is missing a numeric code.',
      );
    }
    if (code != 0) {
      throw BiliApiException(
        json['message']?.toString() ??
            json['msg']?.toString() ??
            'Bilibili recommended live rooms request failed.',
        biliCode: code,
      );
    }

    final rawData = json['data'];
    if (rawData is! List) {
      throw const BpiSerializationException(
        'Bilibili recommended live rooms response is missing a list data '
        'field.',
      );
    }

    return NetworkLiveRecommendedRooms(
      code: code,
      message: json['message']?.toString() ?? json['msg']?.toString() ?? '',
      rooms: biliReadObjectList(
        rawData,
        NetworkLiveRecommendedRoom.tryFromJson,
      ),
    );
  }

  final int code;
  final String message;
  final List<NetworkLiveRecommendedRoom> rooms;
}

final class NetworkLiveRecommendedRoom {
  const NetworkLiveRecommendedRoom({
    required this.roomId,
    this.uid,
    this.title,
    this.uname,
    this.face,
    this.cover,
    this.online,
    this.areaName,
    this.link,
    this.shortId,
  });

  static NetworkLiveRecommendedRoom? tryFromJson(Map<dynamic, dynamic> json) {
    final roomId = biliReadInt(json['roomid']);
    if (roomId == null) {
      return null;
    }
    return NetworkLiveRecommendedRoom(
      roomId: roomId,
      uid: biliReadInt(json['uid']),
      title: biliReadString(json['title']),
      uname: biliReadString(json['uname']),
      face: biliReadString(json['face']),
      cover:
          biliReadString(json['system_cover']) ??
          biliReadString(json['user_cover']),
      online: biliReadInt(json['online']),
      areaName: biliReadString(json['areaName']),
      link: biliReadString(json['link']),
      shortId: biliReadInt(json['short_id']),
    );
  }

  final int roomId;
  final int? uid;
  final String? title;
  final String? uname;
  final String? face;
  final String? cover;
  final int? online;
  final String? areaName;
  final String? link;
  final int? shortId;
}

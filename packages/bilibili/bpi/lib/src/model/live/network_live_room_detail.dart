import 'package:json_annotation/json_annotation.dart';

part 'network_live_room_detail.g.dart';

/// 直播间 H5 详情数据模型 (/xlive/web-room/v1/index/getH5InfoByRoom)
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkLiveRoomDetail {
  const NetworkLiveRoomDetail({
    required this.roomInfo,
    this.anchorInfo,
    this.watchedShow,
  });

  factory NetworkLiveRoomDetail.fromJson(Map<String, dynamic> json) =>
      _$NetworkLiveRoomDetailFromJson(json);

  final NetworkLiveRoomInfo roomInfo;
  final NetworkLiveAnchorInfo? anchorInfo;
  final NetworkLiveWatchedShow? watchedShow;
}

/// 直播间基本信息
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkLiveRoomInfo {
  const NetworkLiveRoomInfo({
    required this.roomId,
    required this.uid,
    required this.title,
    required this.cover,
    this.description,
    required this.liveStatus,
    this.liveStartTime,
    this.areaId,
    this.areaName,
    this.parentAreaId,
    this.parentAreaName,
    this.online,
    this.keyframe,
    this.background,
  });

  factory NetworkLiveRoomInfo.fromJson(Map<String, dynamic> json) =>
      _$NetworkLiveRoomInfoFromJson(json);

  final int roomId;
  final int uid;
  final String title;
  final String cover;
  final String? description;
  final int liveStatus;
  final int? liveStartTime;
  final int? areaId;
  final String? areaName;
  final int? parentAreaId;
  final String? parentAreaName;
  final int? online;
  final String? keyframe;
  final String? background;
}

/// 主播基本信息
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkLiveAnchorInfo {
  const NetworkLiveAnchorInfo({this.baseInfo, this.relationInfo});

  factory NetworkLiveAnchorInfo.fromJson(Map<String, dynamic> json) =>
      _$NetworkLiveAnchorInfoFromJson(json);

  final NetworkLiveAnchorBaseInfo? baseInfo;
  final NetworkLiveAnchorRelationInfo? relationInfo;
}

/// 主播基础资料
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkLiveAnchorBaseInfo {
  const NetworkLiveAnchorBaseInfo({
    required this.uname,
    required this.face,
    this.officialInfo,
  });

  factory NetworkLiveAnchorBaseInfo.fromJson(Map<String, dynamic> json) =>
      _$NetworkLiveAnchorBaseInfoFromJson(json);

  final String uname;
  final String face;
  final NetworkLiveOfficialInfo? officialInfo;
}

/// 主播认证信息
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkLiveOfficialInfo {
  const NetworkLiveOfficialInfo({this.role, this.title, this.desc});

  factory NetworkLiveOfficialInfo.fromJson(Map<String, dynamic> json) =>
      _$NetworkLiveOfficialInfoFromJson(json);

  final int? role;
  final String? title;
  final String? desc;
}

/// 主播关系/粉丝信息
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkLiveAnchorRelationInfo {
  const NetworkLiveAnchorRelationInfo({this.attention});

  factory NetworkLiveAnchorRelationInfo.fromJson(Map<String, dynamic> json) =>
      _$NetworkLiveAnchorRelationInfoFromJson(json);

  final int? attention;
}

/// 观看/人气展现信息
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkLiveWatchedShow {
  const NetworkLiveWatchedShow({this.num, this.textSmall, this.textLarge});

  factory NetworkLiveWatchedShow.fromJson(Map<String, dynamic> json) =>
      _$NetworkLiveWatchedShowFromJson(json);

  final int? num;
  final String? textSmall;
  final String? textLarge;
}

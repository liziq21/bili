import 'package:json_annotation/json_annotation.dart';

part 'network_live_room_play_info.g.dart';

/// 直播间播放流信息数据模型 (/xlive/web-room/v2/index/getRoomPlayInfo)
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkLiveRoomPlayInfo {
  const NetworkLiveRoomPlayInfo({
    required this.roomId,
    this.shortId,
    this.uid,
    this.liveStatus,
    this.liveTime,
    this.playurlInfo,
  });

  factory NetworkLiveRoomPlayInfo.fromJson(Map<String, dynamic> json) =>
      _$NetworkLiveRoomPlayInfoFromJson(json);

  final int roomId;
  final int? shortId;
  final int? uid;
  final int? liveStatus;
  final int? liveTime;
  final NetworkLivePlayurlInfo? playurlInfo;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkLivePlayurlInfo {
  const NetworkLivePlayurlInfo({this.confJson, this.playurl});

  factory NetworkLivePlayurlInfo.fromJson(Map<String, dynamic> json) =>
      _$NetworkLivePlayurlInfoFromJson(json);

  final String? confJson;
  final NetworkLivePlayurlData? playurl;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkLivePlayurlData {
  const NetworkLivePlayurlData({
    this.cid,
    this.gQnDesc = const [],
    this.stream = const [],
  });

  factory NetworkLivePlayurlData.fromJson(Map<String, dynamic> json) =>
      _$NetworkLivePlayurlDataFromJson(json);

  final int? cid;
  final List<NetworkLiveQualityDescription> gQnDesc;
  final List<NetworkLiveStream> stream;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkLiveQualityDescription {
  const NetworkLiveQualityDescription({this.qn, this.desc});

  factory NetworkLiveQualityDescription.fromJson(Map<String, dynamic> json) =>
      _$NetworkLiveQualityDescriptionFromJson(json);

  final int? qn;
  final String? desc;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkLiveStream {
  const NetworkLiveStream({this.protocolName, this.format = const []});

  factory NetworkLiveStream.fromJson(Map<String, dynamic> json) =>
      _$NetworkLiveStreamFromJson(json);

  final String? protocolName;
  final List<NetworkLiveStreamFormat> format;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkLiveStreamFormat {
  const NetworkLiveStreamFormat({this.formatName, this.codec = const []});

  factory NetworkLiveStreamFormat.fromJson(Map<String, dynamic> json) =>
      _$NetworkLiveStreamFormatFromJson(json);

  final String? formatName;
  final List<NetworkLiveStreamCodec> codec;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkLiveStreamCodec {
  const NetworkLiveStreamCodec({
    this.codecName,
    this.currentQn,
    this.acceptQn = const [],
    this.baseUrl,
    this.urlInfo = const [],
  });

  factory NetworkLiveStreamCodec.fromJson(Map<String, dynamic> json) =>
      _$NetworkLiveStreamCodecFromJson(json);

  final String? codecName;
  final int? currentQn;
  final List<int> acceptQn;
  final String? baseUrl;
  final List<NetworkLiveUrlInfo> urlInfo;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkLiveUrlInfo {
  const NetworkLiveUrlInfo({this.host, this.extra, this.streamTtl});

  factory NetworkLiveUrlInfo.fromJson(Map<String, dynamic> json) =>
      _$NetworkLiveUrlInfoFromJson(json);

  final String? host;
  final String? extra;
  final int? streamTtl;
}

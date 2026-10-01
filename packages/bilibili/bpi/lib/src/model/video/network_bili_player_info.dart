import 'package:json_annotation/json_annotation.dart';

part 'network_bili_player_info.g.dart';

/// 视频播放器配置与字幕信息数据模型 (/x/player/v2)
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliPlayerInfo({
  required final int aid,
  required final String bvid,
  required final int cid,
  final int? loginMid,
  final String? loginMidHash,
  final bool? isOwner,
  final String? name,
  final NetworkBiliSubtitleContainer? subtitle,
  final List<NetworkBiliViewPoint>? viewPoints,
  final NetworkBiliBgmInfo? bgmInfo,
}) {
  factory NetworkBiliPlayerInfo.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliPlayerInfoFromJson(json);
}

/// 字幕容器信息
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliSubtitleContainer({
  final bool? allowSubmit,
  final String? lan,
  final String? lanDoc,
  final List<NetworkBiliSubtitleItem>? subtitles,
}) {
  factory NetworkBiliSubtitleContainer.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliSubtitleContainerFromJson(json);
}

/// 单条字幕轨道模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliSubtitleItem({
  required final int id,
  required final String lan,
  // Non-core field: bpi's parsing guideline requires a missing or retyped
  // field to become null rather than rejecting the whole response, so this is
  // nullable even though the Bilibili payload normally carries it, and a
  // non-string value is coerced to null instead of throwing.
  @JsonKey(fromJson: _lanDocFromJson) final String? lanDoc,
  final bool? isMachine,
  required final String subtitleUrl,
  final int? type,
  final String? idStr,
}) {
  factory NetworkBiliSubtitleItem.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliSubtitleItemFromJson(json);
}

/// 视频看点 / 时间轴点模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliViewPoint({
  final int? type,
  final num? from,
  final num? to,
  final String? content,
  final String? imgUrl,
}) {
  factory NetworkBiliViewPoint.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliViewPointFromJson(json);
}

/// 背景音乐信息模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliBgmInfo({
  final String? musicId,
  final String? musicTitle,
  final String? jumpUrl,
}) {
  factory NetworkBiliBgmInfo.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliBgmInfoFromJson(json);
}

/// Coerces upstream `lan_doc` to [String]: a string is kept as is, every other
/// type (number, boolean, list, object) becomes null.
String? _lanDocFromJson(Object? value) => value is String ? value : null;

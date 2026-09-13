import 'package:json_annotation/json_annotation.dart';

part 'network_play_url.g.dart';

Object? _readBaseUrl(Map json, String key) => json['baseUrl'] ?? json['base_url'];
Object? _readBackupUrl(Map json, String key) => json['backupUrl'] ?? json['backup_url'];

/// 视频播放地址详情模型 (/x/player/wbi/playurl)
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkPlayUrl({
  final String? from,
  final String? result,
  final String? message,
  final int? quality,
  final String? format,
  final int? timelength,
  final String? acceptFormat,
  final List<String>? acceptDescription,
  final List<int>? acceptQuality,
  final int? videoCodecid,
  final DashData? dash,
  final List<DurlData>? durl,
  final List<FormatDescription>? supportFormats,
  final VolumeData? volume,
  final int? lastPlayTime,
  final int? lastPlayCid,
}) {
  factory NetworkPlayUrl.fromJson(Map<String, dynamic> json) =>
      _$NetworkPlayUrlFromJson(json);
}

/// DASH 格式流集合
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class DashData({
  final int? duration,
  final double? minBufferTime,
  final List<MediaStreamItem>? video,
  final List<MediaStreamItem>? audio,
}) {
  factory DashData.fromJson(Map<String, dynamic> json) =>
      _$DashDataFromJson(json);
}

/// 音视频流条目 (DASH 中的视频或音频流)
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class MediaStreamItem({
  required final int id,
  @JsonKey(readValue: _readBaseUrl) final String? baseUrl,
  @JsonKey(readValue: _readBackupUrl) final List<String>? backupUrl,
  final int? bandwidth,
  final String? mimeType,
  final String? codecs,
  final int? width,
  final int? height,
  final String? frameRate,
  final String? sar,
  final int? startWithSap,
  final int? codecid,
}) {
  factory MediaStreamItem.fromJson(Map<String, dynamic> json) =>
      _$MediaStreamItemFromJson(json);

  Iterable<String> get playUrls sync* {
    if (baseUrl != null && baseUrl!.isNotEmpty) yield baseUrl!;
    if (backupUrl != null && backupUrl!.isNotEmpty) yield* backupUrl!;
  }
}

/// DURL 单文件流格式
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class DurlData({
  final int? order,
  final int? length,
  final int? size,
  final String? ahead,
  final String? vhead,
  final String? url,
  @JsonKey(readValue: _readBackupUrl) final List<String>? backupUrl,
}) {
  factory DurlData.fromJson(Map<String, dynamic> json) =>
      _$DurlDataFromJson(json);

  Iterable<String> get playUrls sync* {
    if (url != null && url!.isNotEmpty) yield url!;
    if (backupUrl != null && backupUrl!.isNotEmpty) yield* backupUrl!;
  }
}

/// 格式描述/支持清晰度列表
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class FormatDescription({
  final int? quality,
  final String? format,
  final String? newDescription,
  final String? displayDesc,
  final List<String>? codecs,
}) {
  factory FormatDescription.fromJson(Map<String, dynamic> json) =>
      _$FormatDescriptionFromJson(json);
}

/// 音频响度与音量控制信息
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class VolumeData({
  final num? measuredI,
  final num? measuredLra,
  final num? measuredTp,
  final num? measuredThreshold,
  final num? targetOffset,
  final num? targetI,
  final num? targetTp,
}) {
  factory VolumeData.fromJson(Map<String, dynamic> json) =>
      _$VolumeDataFromJson(json);
}

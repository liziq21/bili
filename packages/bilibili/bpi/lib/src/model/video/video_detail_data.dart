import 'package:json_annotation/json_annotation.dart';

part 'video_detail_data.g.dart';

/// 1. 最外层网络响应包裹层
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class BaseResponse({
  required final int code,
  required final String message,
  required final int ttl,
  required final VideoDetailData data,
}) {
  factory fromJson(Map<String, dynamic> json) => _$BaseResponseFromJson(json);
}

/// 2. 核心视频详情数据模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class VideoDetailData({
  required final String bvid,
  required final int aid,
  required final int videos,
  required final int copyright,
  required final String pic,
  required final String title,
  required final int pubdate,
  required final int ctime,
  required final String desc,
  required final List<DescV2> descV2,
  required final int duration,
  required final Rights rights,
  required final Owner owner,
  required final VideoStat stat,
  required final ArgueInfo argueInfo,
  required final int cid,
  required final Dimension dimension,
  required final int seasonId,
  required final bool isUpowerExclusive,
  required final UgcSeason ugcSeason,
}) {
  bool isPageReversed = false;

  factory fromJson(Map<String, dynamic> json) =>
      _$VideoDetailDataFromJson(json);
}

/// 3. 描述文本辅助模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class DescV2({
  required final String rawText, // fieldRename 自动处理为 raw_text
  required final int type,
  required final int bizId, // fieldRename 自动处理为 biz_id
}) {
  factory fromJson(Map<String, dynamic> json) => _$DescV2FromJson(json);
}

/// 4. 权限辅助模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Rights({
  required final int bp,
  required final int elec,
  required final int download,
  required final int movie,
  required final int pay,
  required final int hd5,
  required final int noReprint,
  required final int autoplay,
  required final int ugcPay,
}) {
  factory fromJson(Map<String, dynamic> json) => _$RightsFromJson(json);
}

/// 5. Up主辅助模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Owner({
  required final int mid,
  required final String name,
  required final String face,
}) {
  factory fromJson(Map<String, dynamic> json) => _$OwnerFromJson(json);
}

/// 6. 状态计数辅助模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class VideoStat({
  required final int aid,
  required final int view,
  required final int danmaku,
  required final int reply,
  required final int favorite,
  required final int coin,
  required final int share,
  required final int like,
}) {
  factory fromJson(Map<String, dynamic> json) => _$VideoStatFromJson(json);
}

/// 7. 争议信息辅助模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class ArgueInfo({
  required final String argueMsg,
  required final int argueType,
  required final String argueLink,
}) {
  factory fromJson(Map<String, dynamic> json) => _$ArgueInfoFromJson(json);
}

/// 8. 分辨率尺寸辅助模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Dimension({
  required final int width,
  required final int height,
  required final int rotate,
}) {
  factory fromJson(Map<String, dynamic> json) => _$DimensionFromJson(json);
}

/// 9. 合集/合辑状态辅助模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class UgcSeason({
  required final int id,
  required final String title,
  required final String cover,
  required final int mid,
  required final String intro,
  required final List<Section> sections,
}) {
  factory fromJson(Map<String, dynamic> json) => _$UgcSeasonFromJson(json);
}

/// 10. 合辑小节辅助模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Section({
  required final String title,
  required final int id,
  required final List<Episode> episodes,
}) {
  factory fromJson(Map<String, dynamic> json) => _$SectionFromJson(json);
}

/// 11. 单集/单视频辅助模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Episode({
  required final int id,
  required final int aid,
  required final int cid,
  required final String title,
  required final String bvid,
}) {
  factory fromJson(Map<String, dynamic> json) => _$EpisodeFromJson(json);
}

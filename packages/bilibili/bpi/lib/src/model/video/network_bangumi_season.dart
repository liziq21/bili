import 'package:json_annotation/json_annotation.dart';

part 'network_bangumi_season.g.dart';

/// Bilibili PGC 番剧/剧集 响应包裹类
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBangumiSeasonResponse {
  final int code;
  final String message;
  final NetworkBangumiSeasonData? result;

  const NetworkBangumiSeasonResponse({
    required this.code,
    required this.message,
    this.result,
  });

  factory NetworkBangumiSeasonResponse.fromJson(Map<String, dynamic> json) =>
      _$NetworkBangumiSeasonResponseFromJson(json);
}

/// Bilibili PGC 番剧/剧集 核心数据模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBangumiSeasonData {
  final int seasonId;
  final String? seasonTitle;
  final String? title;
  final String? cover;
  final String? evaluate;
  final String? link;
  final List<NetworkBangumiEpisode>? episodes;
  final NetworkBangumiSeasonStat? stat;
  final NetworkBangumiUpInfo? upInfo;
  final NetworkBangumiRating? rating;
  final List<NetworkBangumiArea>? areas;
  final String? actors;
  final String? alias;

  const NetworkBangumiSeasonData({
    required this.seasonId,
    this.seasonTitle,
    this.title,
    this.cover,
    this.evaluate,
    this.link,
    this.episodes,
    this.stat,
    this.upInfo,
    this.rating,
    this.areas,
    this.actors,
    this.alias,
  });

  factory NetworkBangumiSeasonData.fromJson(Map<String, dynamic> json) =>
      _$NetworkBangumiSeasonDataFromJson(json);
}

/// 单集辅助模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBangumiEpisode {
  @JsonKey(name: 'ep_id')
  final int epId;
  final int? aid;
  final String? bvid;
  final int? cid;
  final String? title;
  final String? longTitle;
  final String? cover;
  final String? badge;
  final int? pubTime;
  final int? duration;
  final String? link;

  const NetworkBangumiEpisode({
    required this.epId,
    this.aid,
    this.bvid,
    this.cid,
    this.title,
    this.longTitle,
    this.cover,
    this.badge,
    this.pubTime,
    this.duration,
    this.link,
  });

  factory NetworkBangumiEpisode.fromJson(Map<String, dynamic> json) =>
      _$NetworkBangumiEpisodeFromJson(json);
}

/// 播放与互动状态辅助模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBangumiSeasonStat {
  final int? views;
  final int? favorites;
  final int? coins;
  final int? likes;
  final int? danmaku;
  final int? reply;
  final int? share;

  const NetworkBangumiSeasonStat({
    this.views,
    this.favorites,
    this.coins,
    this.likes,
    this.danmaku,
    this.reply,
    this.share,
  });

  factory NetworkBangumiSeasonStat.fromJson(Map<String, dynamic> json) =>
      _$NetworkBangumiSeasonStatFromJson(json);
}

/// UP 主辅助模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBangumiUpInfo {
  final int? mid;
  final String? uname;
  final String? avatar;

  const NetworkBangumiUpInfo({this.mid, this.uname, this.avatar});

  factory NetworkBangumiUpInfo.fromJson(Map<String, dynamic> json) =>
      _$NetworkBangumiUpInfoFromJson(json);
}

/// 评分辅助模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBangumiRating {
  final double? score;
  final int? count;

  const NetworkBangumiRating({this.score, this.count});

  factory NetworkBangumiRating.fromJson(Map<String, dynamic> json) =>
      _$NetworkBangumiRatingFromJson(json);
}

/// 地区辅助模型
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBangumiArea {
  final int? id;
  final String? name;

  const NetworkBangumiArea({this.id, this.name});

  factory NetworkBangumiArea.fromJson(Map<String, dynamic> json) =>
      _$NetworkBangumiAreaFromJson(json);
}

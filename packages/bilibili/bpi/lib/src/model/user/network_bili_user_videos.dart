import 'package:json_annotation/json_annotation.dart';

import '../../converter/int_or_string_converter.dart';

part 'network_bili_user_videos.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliUserVideosData {
  const NetworkBiliUserVideosData({
    this.list,
    this.page,
    this.episodicButton,
    this.isRisk,
    this.gaiaResType,
    this.gaiaData,
  });

  final NetworkBiliUserVideosList? list;
  final NetworkBiliUserVideosPage? page;
  final NetworkBiliUserVideosEpisodicButton? episodicButton;
  final bool? isRisk;
  final int? gaiaResType;
  final Object? gaiaData;

  factory NetworkBiliUserVideosData.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliUserVideosDataFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliUserVideosList {
  const NetworkBiliUserVideosList({this.slist, this.tlist, this.vlist});

  final List<Object?>? slist;
  @NetworkBiliUserVideosTlistConverter()
  final Map<String, NetworkBiliUserVideosTlistEntry>? tlist;
  @NetworkBiliVideoListConverter()
  final List<NetworkBiliUserVideoItem>? vlist;

  factory NetworkBiliUserVideosList.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliUserVideosListFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliUserVideosTlistEntry {
  const NetworkBiliUserVideosTlistEntry({this.tid, this.count, this.name});

  @NullableIntOrStringConverter()
  final int? tid;
  @NullableIntOrStringConverter()
  final int? count;
  final String? name;

  factory NetworkBiliUserVideosTlistEntry.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliUserVideosTlistEntryFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliUserVideoItem {
  const NetworkBiliUserVideoItem({
    required this.aid,
    required this.bvid,
    this.attribute,
    this.author,
    this.comment,
    this.copyright,
    this.created,
    this.description,
    this.elecArcBadge,
    this.elecArcType,
    this.enableVt,
    this.hideClick,
    this.isAvoided,
    this.isChargingArc,
    this.isLessonFinished,
    this.isLessonVideo,
    this.isLivePlayback,
    this.isPay,
    this.isSelfView,
    this.isSteinsGate,
    this.isUnionVideo,
    this.jumpUrl,
    this.length,
    this.lessonUpdateInfo,
    this.meta,
    this.mid,
    this.pic,
    this.play,
    this.playbackPosition,
    this.review,
    this.seasonId,
    this.subtitle,
    this.title,
    this.typeid,
    this.videoReview,
    this.viewSelfType,
    this.vt,
    this.vtDisplay,
  });

  final int aid;
  final String bvid;
  @NullableIntOrStringConverter()
  final int? attribute;
  final String? author;
  @NullableIntOrStringConverter()
  final int? comment;
  final String? copyright;
  @NullableIntOrStringConverter()
  final int? created;
  final String? description;
  final String? elecArcBadge;
  @NullableIntOrStringConverter()
  final int? elecArcType;
  @NullableIntOrStringConverter()
  final int? enableVt;
  final bool? hideClick;
  @NullableIntOrStringConverter()
  final int? isAvoided;
  final bool? isChargingArc;
  @NullableIntOrStringConverter()
  final int? isLessonFinished;
  @NullableIntOrStringConverter()
  final int? isLessonVideo;
  @NullableIntOrStringConverter()
  final int? isLivePlayback;
  @NullableIntOrStringConverter()
  final int? isPay;
  final bool? isSelfView;
  @NullableIntOrStringConverter()
  final int? isSteinsGate;
  @NullableIntOrStringConverter()
  final int? isUnionVideo;
  final String? jumpUrl;
  final String? length;
  final String? lessonUpdateInfo;
  final NetworkBiliUserVideoMeta? meta;
  @NullableIntOrStringConverter()
  final int? mid;
  final String? pic;
  @NullableIntOrStringConverter()
  final int? play;
  @NullableIntOrStringConverter()
  final int? playbackPosition;
  @NullableIntOrStringConverter()
  final int? review;
  @NullableIntOrStringConverter()
  final int? seasonId;
  final String? subtitle;
  final String? title;
  @NullableIntOrStringConverter()
  final int? typeid;
  @NullableIntOrStringConverter()
  final int? videoReview;
  @NullableIntOrStringConverter()
  final int? viewSelfType;
  @NullableIntOrStringConverter()
  final int? vt;
  final String? vtDisplay;

  factory NetworkBiliUserVideoItem.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliUserVideoItemFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliUserVideoMeta {
  const NetworkBiliUserVideoMeta({
    this.attribute,
    this.cover,
    this.epCount,
    this.epNum,
    this.firstAid,
    this.id,
    this.intro,
    this.mid,
    this.ptime,
    this.signState,
    this.stat,
    this.title,
    this.show,
  });

  @NullableIntOrStringConverter()
  final int? attribute;
  final String? cover;
  @NullableIntOrStringConverter()
  final int? epCount;
  @NullableIntOrStringConverter()
  final int? epNum;
  @NullableIntOrStringConverter()
  final int? firstAid;
  @NullableIntOrStringConverter()
  final int? id;
  final String? intro;
  @NullableIntOrStringConverter()
  final int? mid;
  @NullableIntOrStringConverter()
  final int? ptime;
  @NullableIntOrStringConverter()
  final int? signState;
  final NetworkBiliUserVideoMetaStat? stat;
  final String? title;
  @NullableIntOrStringConverter()
  final int? show;

  factory NetworkBiliUserVideoMeta.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliUserVideoMetaFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliUserVideoMetaStat {
  const NetworkBiliUserVideoMetaStat({
    this.coin,
    this.danmaku,
    this.favorite,
    this.like,
    this.mtime,
    this.reply,
    this.seasonId,
    this.share,
    this.view,
    this.vt,
    this.vv,
  });

  @NullableIntOrStringConverter()
  final int? coin;
  @NullableIntOrStringConverter()
  final int? danmaku;
  @NullableIntOrStringConverter()
  final int? favorite;
  @NullableIntOrStringConverter()
  final int? like;
  @NullableIntOrStringConverter()
  final int? mtime;
  @NullableIntOrStringConverter()
  final int? reply;
  @NullableIntOrStringConverter()
  final int? seasonId;
  @NullableIntOrStringConverter()
  final int? share;
  @NullableIntOrStringConverter()
  final int? view;
  @NullableIntOrStringConverter()
  final int? vt;
  @NullableIntOrStringConverter()
  final int? vv;

  factory NetworkBiliUserVideoMetaStat.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliUserVideoMetaStatFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliUserVideosPage {
  const NetworkBiliUserVideosPage({this.count, this.pn, this.ps});

  @NullableIntOrStringConverter()
  final int? count;
  @NullableIntOrStringConverter()
  final int? pn;
  @NullableIntOrStringConverter()
  final int? ps;

  factory NetworkBiliUserVideosPage.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliUserVideosPageFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliUserVideosEpisodicButton {
  const NetworkBiliUserVideosEpisodicButton({this.text, this.uri});

  final String? text;
  final String? uri;

  factory NetworkBiliUserVideosEpisodicButton.fromJson(
    Map<String, dynamic> json,
  ) => _$NetworkBiliUserVideosEpisodicButtonFromJson(json);
}

/// 解析投稿视频列表，跳过缺核心标识 `bvid` 或 `aid` 的条目。
///
/// 依据 AGENTS.md「缺少核心标识的 item 必须跳过」：单条坏视频不应让整页
/// `vlist` 解析失败。缺 `bvid` 或 `aid` 的条目被丢弃，其余条目正常解析；
/// 缺 `title` 等非核心字段的条目保留，缺失字段读为 null。
class NetworkBiliVideoListConverter
    implements JsonConverter<List<NetworkBiliUserVideoItem>?, Object?> {
  const NetworkBiliVideoListConverter();

  @override
  List<NetworkBiliUserVideoItem>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! List) return null;
    final items = <NetworkBiliUserVideoItem>[];
    for (final entry in json) {
      if (entry is! Map) continue;
      // 核心标识缺失的条目跳过，不影响整页。
      final bvid = entry['bvid'];
      final aid = entry['aid'];
      if (bvid is! String || bvid.isEmpty) continue;
      if (aid is! num) continue;
      items.add(
        NetworkBiliUserVideoItem.fromJson(Map<String, dynamic>.from(entry)),
      );
    }
    return items;
  }

  @override
  Object? toJson(List<NetworkBiliUserVideoItem>? object) => object;
}

/// 解析分区索引（tlist），其键为分区 tid 的字符串形式。
///
/// tlist 的键是动态的（分区 tid 作为字符串键），json_serializable 不会
/// 为 Map 值调用 `fromJson`，因此需要自定义 converter 逐项解析。
class NetworkBiliUserVideosTlistConverter
    implements
        JsonConverter<Map<String, NetworkBiliUserVideosTlistEntry>?, Object?> {
  const NetworkBiliUserVideosTlistConverter();

  @override
  Map<String, NetworkBiliUserVideosTlistEntry>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! Map) return null;
    final result = <String, NetworkBiliUserVideosTlistEntry>{};
    for (final entry in json.entries) {
      if (entry.value is! Map) continue;
      result['${entry.key}'] = NetworkBiliUserVideosTlistEntry.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }
    return result;
  }

  @override
  Object? toJson(Map<String, NetworkBiliUserVideosTlistEntry>? object) =>
      object;
}

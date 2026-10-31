import 'package:json_annotation/json_annotation.dart';

import '../../converter/int_or_string_converter.dart';

part 'network_bili_playlist_content.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliPlaylistContentData {
  const NetworkBiliPlaylistContentData({this.itemsLists});

  final NetworkBiliPlaylistItemsLists? itemsLists;

  factory NetworkBiliPlaylistContentData.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliPlaylistContentDataFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliPlaylistItemsLists {
  const NetworkBiliPlaylistItemsLists({
    this.page,
    this.seasonsList,
    this.seriesList,
  });

  final NetworkBiliPlaylistPage? page;
  final List<NetworkBiliPlaylistSeason>? seasonsList;
  @NetworkBiliPlaylistSeriesConverter()
  final List<NetworkBiliPlaylistSeries>? seriesList;

  factory NetworkBiliPlaylistItemsLists.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliPlaylistItemsListsFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliPlaylistPage {
  const NetworkBiliPlaylistPage({this.pageNum, this.pageSize, this.total});

  @NullableIntOrStringConverter()
  final int? pageNum;
  @NullableIntOrStringConverter()
  final int? pageSize;
  @NullableIntOrStringConverter()
  final int? total;

  factory NetworkBiliPlaylistPage.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliPlaylistPageFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliPlaylistSeason {
  const NetworkBiliPlaylistSeason({
    this.aids,
    this.archives,
    this.meta,
    this.page,
  });

  final List<int>? aids;
  final List<NetworkBiliPlaylistVideoItem>? archives;
  final NetworkBiliPlaylistSeasonMeta? meta;
  final NetworkBiliPlaylistSeasonPage? page;

  factory NetworkBiliPlaylistSeason.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliPlaylistSeasonFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliPlaylistSeasonMeta {
  const NetworkBiliPlaylistSeasonMeta({
    this.category,
    this.cover,
    this.description,
    this.mid,
    this.name,
    this.ptime,
    this.seasonId,
    this.total,
  });

  @NullableIntOrStringConverter()
  final int? category;
  final String? cover;
  final String? description;
  @NullableIntOrStringConverter()
  final int? mid;
  final String? name;
  @NullableIntOrStringConverter()
  final int? ptime;
  @NullableIntOrStringConverter()
  final int? seasonId;
  @NullableIntOrStringConverter()
  final int? total;

  factory NetworkBiliPlaylistSeasonMeta.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliPlaylistSeasonMetaFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliPlaylistSeasonPage {
  const NetworkBiliPlaylistSeasonPage({
    this.pageNum,
    this.pageSize,
    this.total,
  });

  @NullableIntOrStringConverter()
  final int? pageNum;
  @NullableIntOrStringConverter()
  final int? pageSize;
  @NullableIntOrStringConverter()
  final int? total;

  factory NetworkBiliPlaylistSeasonPage.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliPlaylistSeasonPageFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliPlaylistSeries {
  const NetworkBiliPlaylistSeries({this.archives, this.meta, this.recentAids});

  final List<NetworkBiliPlaylistVideoItem>? archives;
  final NetworkBiliPlaylistSeriesMeta? meta;
  final List<int>? recentAids;

  factory NetworkBiliPlaylistSeries.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliPlaylistSeriesFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliPlaylistSeriesMeta {
  const NetworkBiliPlaylistSeriesMeta({
    this.category,
    this.cover,
    this.creator,
    this.ctime,
    this.description,
    this.keywords,
    this.lastUpdateTs,
    this.mid,
    this.mtime,
    this.name,
    this.rawKeywords,
    this.seriesId,
    this.state,
    this.total,
  });

  @NullableIntOrStringConverter()
  final int? category;
  final String? cover;
  final String? creator;
  @NullableIntOrStringConverter()
  final int? ctime;
  final String? description;
  final List<String>? keywords;
  @NullableIntOrStringConverter()
  final int? lastUpdateTs;
  @NullableIntOrStringConverter()
  final int? mid;
  @NullableIntOrStringConverter()
  final int? mtime;
  final String? name;
  final String? rawKeywords;
  @NullableIntOrStringConverter()
  final int? seriesId;
  @NullableIntOrStringConverter()
  final int? state;
  @NullableIntOrStringConverter()
  final int? total;

  factory NetworkBiliPlaylistSeriesMeta.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliPlaylistSeriesMetaFromJson(json);
}

/// 解析系列列表，跳过缺核心标识 `series_id` 的条目。
class NetworkBiliPlaylistSeriesConverter
    implements JsonConverter<List<NetworkBiliPlaylistSeries>?, Object?> {
  const NetworkBiliPlaylistSeriesConverter();

  @override
  List<NetworkBiliPlaylistSeries>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is! List) return null;
    final items = <NetworkBiliPlaylistSeries>[];
    for (final entry in json) {
      if (entry is! Map) continue;
      final seriesId = entry['series_id'];
      if (seriesId is! num) continue;
      items.add(
        NetworkBiliPlaylistSeries.fromJson(Map<String, dynamic>.from(entry)),
      );
    }
    return items;
  }

  @override
  Object? toJson(List<NetworkBiliPlaylistSeries>? object) => object;
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliPlaylistVideoItem {
  const NetworkBiliPlaylistVideoItem({
    required this.aid,
    required this.bvid,
    this.attribute,
    this.author,
    this.comment,
    this.copyright,
    this.created,
    this.ctime,
    this.description,
    this.duration,
    this.elecArcBadge,
    this.elecArcType,
    this.enableVt,
    this.hideClick,
    this.interactiveVideo,
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
    this.pubdate,
    this.review,
    this.seasonId,
    this.state,
    this.subtitle,
    this.title,
    this.typeid,
    this.ugcPay,
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
  @NullableIntOrStringConverter()
  final int? ctime;
  final String? description;
  @NullableIntOrStringConverter()
  final int? duration;
  final String? elecArcBadge;
  @NullableIntOrStringConverter()
  final int? elecArcType;
  @NullableIntOrStringConverter()
  final int? enableVt;
  final bool? hideClick;
  final bool? interactiveVideo;
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
  final NetworkBiliPlaylistVideoMeta? meta;
  @NullableIntOrStringConverter()
  final int? mid;
  final String? pic;
  @NullableIntOrStringConverter()
  final int? play;
  @NullableIntOrStringConverter()
  final int? playbackPosition;
  @NullableIntOrStringConverter()
  final int? pubdate;
  @NullableIntOrStringConverter()
  final int? review;
  @NullableIntOrStringConverter()
  final int? seasonId;
  @NullableIntOrStringConverter()
  final int? state;
  final String? subtitle;
  final String? title;
  @NullableIntOrStringConverter()
  final int? typeid;
  @NullableIntOrStringConverter()
  final int? ugcPay;
  @NullableIntOrStringConverter()
  final int? videoReview;
  @NullableIntOrStringConverter()
  final int? viewSelfType;
  @NullableIntOrStringConverter()
  final int? vt;
  final String? vtDisplay;

  factory NetworkBiliPlaylistVideoItem.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliPlaylistVideoItemFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliPlaylistVideoMeta {
  const NetworkBiliPlaylistVideoMeta({
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
  final NetworkBiliPlaylistVideoMetaStat? stat;
  final String? title;
  @NullableIntOrStringConverter()
  final int? show;

  factory NetworkBiliPlaylistVideoMeta.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliPlaylistVideoMetaFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliPlaylistVideoMetaStat {
  const NetworkBiliPlaylistVideoMetaStat({
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

  factory NetworkBiliPlaylistVideoMetaStat.fromJson(
    Map<String, dynamic> json,
  ) => _$NetworkBiliPlaylistVideoMetaStatFromJson(json);
}

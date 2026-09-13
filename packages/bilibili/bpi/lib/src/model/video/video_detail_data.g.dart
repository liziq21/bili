// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_detail_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BaseResponse _$BaseResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BaseResponse', json, ($checkedConvert) {
      final val = BaseResponse(
        code: $checkedConvert('code', (v) => (v as num).toInt()),
        message: $checkedConvert('message', (v) => v as String),
        ttl: $checkedConvert('ttl', (v) => (v as num).toInt()),
        data: $checkedConvert(
          'data',
          (v) => VideoDetailData.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

VideoDetailData _$VideoDetailDataFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'VideoDetailData',
  json,
  ($checkedConvert) {
    final val = VideoDetailData(
      bvid: $checkedConvert('bvid', (v) => v as String),
      aid: $checkedConvert('aid', (v) => (v as num).toInt()),
      videos: $checkedConvert('videos', (v) => (v as num).toInt()),
      copyright: $checkedConvert('copyright', (v) => (v as num).toInt()),
      pic: $checkedConvert('pic', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      pubdate: $checkedConvert('pubdate', (v) => (v as num).toInt()),
      ctime: $checkedConvert('ctime', (v) => (v as num).toInt()),
      desc: $checkedConvert('desc', (v) => v as String),
      descV2: $checkedConvert(
        'desc_v2',
        (v) => (v as List<dynamic>?)
            ?.map((e) => DescV2.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      duration: $checkedConvert('duration', (v) => (v as num).toInt()),
      rights: $checkedConvert(
        'rights',
        (v) => Rights.fromJson(v as Map<String, dynamic>),
      ),
      owner: $checkedConvert(
        'owner',
        (v) => Owner.fromJson(v as Map<String, dynamic>),
      ),
      stat: $checkedConvert(
        'stat',
        (v) => VideoStat.fromJson(v as Map<String, dynamic>),
      ),
      argueInfo: $checkedConvert(
        'argue_info',
        (v) => v == null ? null : ArgueInfo.fromJson(v as Map<String, dynamic>),
      ),
      cid: $checkedConvert('cid', (v) => (v as num).toInt()),
      dimension: $checkedConvert(
        'dimension',
        (v) => Dimension.fromJson(v as Map<String, dynamic>),
      ),
      seasonId: $checkedConvert('season_id', (v) => (v as num?)?.toInt()),
      isUpowerExclusive: $checkedConvert(
        'is_upower_exclusive',
        (v) => v as bool,
      ),
      ugcSeason: $checkedConvert(
        'ugc_season',
        (v) => v == null ? null : UgcSeason.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'descV2': 'desc_v2',
    'argueInfo': 'argue_info',
    'seasonId': 'season_id',
    'isUpowerExclusive': 'is_upower_exclusive',
    'ugcSeason': 'ugc_season',
  },
);

DescV2 _$DescV2FromJson(Map<String, dynamic> json) =>
    $checkedCreate('DescV2', json, ($checkedConvert) {
      final val = DescV2(
        rawText: $checkedConvert('raw_text', (v) => v as String),
        type: $checkedConvert('type', (v) => (v as num).toInt()),
        bizId: $checkedConvert('biz_id', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'rawText': 'raw_text', 'bizId': 'biz_id'});

Rights _$RightsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Rights', json, ($checkedConvert) {
      final val = Rights(
        bp: $checkedConvert('bp', (v) => (v as num).toInt()),
        elec: $checkedConvert('elec', (v) => (v as num).toInt()),
        download: $checkedConvert('download', (v) => (v as num).toInt()),
        movie: $checkedConvert('movie', (v) => (v as num).toInt()),
        pay: $checkedConvert('pay', (v) => (v as num).toInt()),
        hd5: $checkedConvert('hd5', (v) => (v as num).toInt()),
        noReprint: $checkedConvert('no_reprint', (v) => (v as num).toInt()),
        autoplay: $checkedConvert('autoplay', (v) => (v as num).toInt()),
        ugcPay: $checkedConvert('ugc_pay', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'noReprint': 'no_reprint', 'ugcPay': 'ugc_pay'});

Owner _$OwnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Owner', json, ($checkedConvert) {
      final val = Owner(
        mid: $checkedConvert('mid', (v) => (v as num).toInt()),
        name: $checkedConvert('name', (v) => v as String),
        face: $checkedConvert('face', (v) => v as String),
      );
      return val;
    });

VideoStat _$VideoStatFromJson(Map<String, dynamic> json) =>
    $checkedCreate('VideoStat', json, ($checkedConvert) {
      final val = VideoStat(
        aid: $checkedConvert('aid', (v) => (v as num).toInt()),
        view: $checkedConvert('view', (v) => (v as num).toInt()),
        danmaku: $checkedConvert('danmaku', (v) => (v as num).toInt()),
        reply: $checkedConvert('reply', (v) => (v as num).toInt()),
        favorite: $checkedConvert('favorite', (v) => (v as num).toInt()),
        coin: $checkedConvert('coin', (v) => (v as num).toInt()),
        share: $checkedConvert('share', (v) => (v as num).toInt()),
        like: $checkedConvert('like', (v) => (v as num).toInt()),
      );
      return val;
    });

ArgueInfo _$ArgueInfoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ArgueInfo',
  json,
  ($checkedConvert) {
    final val = ArgueInfo(
      argueMsg: $checkedConvert('argue_msg', (v) => v as String),
      argueType: $checkedConvert('argue_type', (v) => (v as num).toInt()),
      argueLink: $checkedConvert('argue_link', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'argueMsg': 'argue_msg',
    'argueType': 'argue_type',
    'argueLink': 'argue_link',
  },
);

Dimension _$DimensionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Dimension', json, ($checkedConvert) {
      final val = Dimension(
        width: $checkedConvert('width', (v) => (v as num).toInt()),
        height: $checkedConvert('height', (v) => (v as num).toInt()),
        rotate: $checkedConvert('rotate', (v) => (v as num).toInt()),
      );
      return val;
    });

UgcSeason _$UgcSeasonFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UgcSeason', json, ($checkedConvert) {
      final val = UgcSeason(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        title: $checkedConvert('title', (v) => v as String),
        cover: $checkedConvert('cover', (v) => v as String),
        mid: $checkedConvert('mid', (v) => (v as num).toInt()),
        intro: $checkedConvert('intro', (v) => v as String),
        sections: $checkedConvert(
          'sections',
          (v) => (v as List<dynamic>)
              .map((e) => Section.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Section _$SectionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Section', json, ($checkedConvert) {
      final val = Section(
        title: $checkedConvert('title', (v) => v as String),
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        episodes: $checkedConvert(
          'episodes',
          (v) => (v as List<dynamic>)
              .map((e) => Episode.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Episode _$EpisodeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Episode', json, ($checkedConvert) {
      final val = Episode(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        aid: $checkedConvert('aid', (v) => (v as num).toInt()),
        cid: $checkedConvert('cid', (v) => (v as num).toInt()),
        title: $checkedConvert('title', (v) => v as String),
        bvid: $checkedConvert('bvid', (v) => v as String),
      );
      return val;
    });

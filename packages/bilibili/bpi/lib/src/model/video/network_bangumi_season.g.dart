// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_bangumi_season.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkBangumiSeasonResponse _$NetworkBangumiSeasonResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBangumiSeasonResponse', json, ($checkedConvert) {
  final val = NetworkBangumiSeasonResponse(
    code: $checkedConvert('code', (v) => (v as num).toInt()),
    message: $checkedConvert('message', (v) => v as String),
    result: $checkedConvert(
      'result',
      (v) => v == null
          ? null
          : NetworkBangumiSeasonData.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

NetworkBangumiSeasonData _$NetworkBangumiSeasonDataFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkBangumiSeasonData',
  json,
  ($checkedConvert) {
    final val = NetworkBangumiSeasonData(
      seasonId: $checkedConvert('season_id', (v) => (v as num).toInt()),
      seasonTitle: $checkedConvert('season_title', (v) => v as String?),
      title: $checkedConvert('title', (v) => v as String?),
      cover: $checkedConvert('cover', (v) => v as String?),
      evaluate: $checkedConvert('evaluate', (v) => v as String?),
      link: $checkedConvert('link', (v) => v as String?),
      episodes: $checkedConvert(
        'episodes',
        (v) => (v as List<dynamic>?)
            ?.map(
              (e) => NetworkBangumiEpisode.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      stat: $checkedConvert(
        'stat',
        (v) => v == null
            ? null
            : NetworkBangumiSeasonStat.fromJson(v as Map<String, dynamic>),
      ),
      upInfo: $checkedConvert(
        'up_info',
        (v) => v == null
            ? null
            : NetworkBangumiUpInfo.fromJson(v as Map<String, dynamic>),
      ),
      rating: $checkedConvert(
        'rating',
        (v) => v == null
            ? null
            : NetworkBangumiRating.fromJson(v as Map<String, dynamic>),
      ),
      areas: $checkedConvert(
        'areas',
        (v) => (v as List<dynamic>?)
            ?.map((e) => NetworkBangumiArea.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      actors: $checkedConvert('actors', (v) => v as String?),
      alias: $checkedConvert('alias', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'seasonId': 'season_id',
    'seasonTitle': 'season_title',
    'upInfo': 'up_info',
  },
);

NetworkBangumiEpisode _$NetworkBangumiEpisodeFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkBangumiEpisode',
  json,
  ($checkedConvert) {
    final val = NetworkBangumiEpisode(
      epId: $checkedConvert('ep_id', (v) => (v as num).toInt()),
      aid: $checkedConvert('aid', (v) => (v as num?)?.toInt()),
      bvid: $checkedConvert('bvid', (v) => v as String?),
      cid: $checkedConvert('cid', (v) => (v as num?)?.toInt()),
      title: $checkedConvert('title', (v) => v as String?),
      longTitle: $checkedConvert('long_title', (v) => v as String?),
      cover: $checkedConvert('cover', (v) => v as String?),
      badge: $checkedConvert('badge', (v) => v as String?),
      pubTime: $checkedConvert('pub_time', (v) => (v as num?)?.toInt()),
      duration: $checkedConvert('duration', (v) => (v as num?)?.toInt()),
      link: $checkedConvert('link', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'epId': 'ep_id',
    'longTitle': 'long_title',
    'pubTime': 'pub_time',
  },
);

NetworkBangumiSeasonStat _$NetworkBangumiSeasonStatFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBangumiSeasonStat', json, ($checkedConvert) {
  final val = NetworkBangumiSeasonStat(
    views: $checkedConvert('views', (v) => (v as num?)?.toInt()),
    favorites: $checkedConvert('favorites', (v) => (v as num?)?.toInt()),
    coins: $checkedConvert('coins', (v) => (v as num?)?.toInt()),
    likes: $checkedConvert('likes', (v) => (v as num?)?.toInt()),
    danmaku: $checkedConvert('danmaku', (v) => (v as num?)?.toInt()),
    reply: $checkedConvert('reply', (v) => (v as num?)?.toInt()),
    share: $checkedConvert('share', (v) => (v as num?)?.toInt()),
  );
  return val;
});

NetworkBangumiUpInfo _$NetworkBangumiUpInfoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBangumiUpInfo', json, ($checkedConvert) {
  final val = NetworkBangumiUpInfo(
    mid: $checkedConvert('mid', (v) => (v as num?)?.toInt()),
    uname: $checkedConvert('uname', (v) => v as String?),
    avatar: $checkedConvert('avatar', (v) => v as String?),
  );
  return val;
});

NetworkBangumiRating _$NetworkBangumiRatingFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBangumiRating', json, ($checkedConvert) {
  final val = NetworkBangumiRating(
    score: $checkedConvert('score', (v) => (v as num?)?.toDouble()),
    count: $checkedConvert('count', (v) => (v as num?)?.toInt()),
  );
  return val;
});

NetworkBangumiArea _$NetworkBangumiAreaFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NetworkBangumiArea', json, ($checkedConvert) {
      final val = NetworkBangumiArea(
        id: $checkedConvert('id', (v) => (v as num?)?.toInt()),
        name: $checkedConvert('name', (v) => v as String?),
      );
      return val;
    });

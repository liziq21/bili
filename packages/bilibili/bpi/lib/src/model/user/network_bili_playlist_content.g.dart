// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_bili_playlist_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkBiliPlaylistContentData _$NetworkBiliPlaylistContentDataFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBiliPlaylistContentData', json, ($checkedConvert) {
  final val = NetworkBiliPlaylistContentData(
    itemsLists: $checkedConvert(
      'items_lists',
      (v) => v == null
          ? null
          : NetworkBiliPlaylistItemsLists.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
}, fieldKeyMap: const {'itemsLists': 'items_lists'});

NetworkBiliPlaylistItemsLists _$NetworkBiliPlaylistItemsListsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkBiliPlaylistItemsLists',
  json,
  ($checkedConvert) {
    final val = NetworkBiliPlaylistItemsLists(
      page: $checkedConvert(
        'page',
        (v) => v == null
            ? null
            : NetworkBiliPlaylistPage.fromJson(v as Map<String, dynamic>),
      ),
      seasonsList: $checkedConvert(
        'seasons_list',
        (v) => (v as List<dynamic>?)
            ?.map(
              (e) =>
                  NetworkBiliPlaylistSeason.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      seriesList: $checkedConvert(
        'series_list',
        (v) => const NetworkBiliPlaylistSeriesConverter().fromJson(v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'seasonsList': 'seasons_list',
    'seriesList': 'series_list',
  },
);

NetworkBiliPlaylistPage _$NetworkBiliPlaylistPageFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBiliPlaylistPage', json, ($checkedConvert) {
  final val = NetworkBiliPlaylistPage(
    pageNum: $checkedConvert(
      'page_num',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
    pageSize: $checkedConvert(
      'page_size',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
    total: $checkedConvert(
      'total',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
  );
  return val;
}, fieldKeyMap: const {'pageNum': 'page_num', 'pageSize': 'page_size'});

NetworkBiliPlaylistSeason _$NetworkBiliPlaylistSeasonFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBiliPlaylistSeason', json, ($checkedConvert) {
  final val = NetworkBiliPlaylistSeason(
    aids: $checkedConvert(
      'aids',
      (v) => (v as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
    ),
    archives: $checkedConvert(
      'archives',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => NetworkBiliPlaylistVideoItem.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
    meta: $checkedConvert(
      'meta',
      (v) => v == null
          ? null
          : NetworkBiliPlaylistSeasonMeta.fromJson(v as Map<String, dynamic>),
    ),
    page: $checkedConvert(
      'page',
      (v) => v == null
          ? null
          : NetworkBiliPlaylistSeasonPage.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

NetworkBiliPlaylistSeasonMeta _$NetworkBiliPlaylistSeasonMetaFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBiliPlaylistSeasonMeta', json, ($checkedConvert) {
  final val = NetworkBiliPlaylistSeasonMeta(
    category: $checkedConvert(
      'category',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
    cover: $checkedConvert('cover', (v) => v as String?),
    description: $checkedConvert('description', (v) => v as String?),
    mid: $checkedConvert(
      'mid',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
    name: $checkedConvert('name', (v) => v as String?),
    ptime: $checkedConvert(
      'ptime',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
    seasonId: $checkedConvert(
      'season_id',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
    total: $checkedConvert(
      'total',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
  );
  return val;
}, fieldKeyMap: const {'seasonId': 'season_id'});

NetworkBiliPlaylistSeasonPage _$NetworkBiliPlaylistSeasonPageFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBiliPlaylistSeasonPage', json, ($checkedConvert) {
  final val = NetworkBiliPlaylistSeasonPage(
    pageNum: $checkedConvert(
      'page_num',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
    pageSize: $checkedConvert(
      'page_size',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
    total: $checkedConvert(
      'total',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
  );
  return val;
}, fieldKeyMap: const {'pageNum': 'page_num', 'pageSize': 'page_size'});

NetworkBiliPlaylistSeries _$NetworkBiliPlaylistSeriesFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBiliPlaylistSeries', json, ($checkedConvert) {
  final val = NetworkBiliPlaylistSeries(
    archives: $checkedConvert(
      'archives',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => NetworkBiliPlaylistVideoItem.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
    meta: $checkedConvert(
      'meta',
      (v) => v == null
          ? null
          : NetworkBiliPlaylistSeriesMeta.fromJson(v as Map<String, dynamic>),
    ),
    recentAids: $checkedConvert(
      'recent_aids',
      (v) => (v as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'recentAids': 'recent_aids'});

NetworkBiliPlaylistSeriesMeta _$NetworkBiliPlaylistSeriesMetaFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkBiliPlaylistSeriesMeta',
  json,
  ($checkedConvert) {
    final val = NetworkBiliPlaylistSeriesMeta(
      category: $checkedConvert(
        'category',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      cover: $checkedConvert('cover', (v) => v as String?),
      creator: $checkedConvert('creator', (v) => v as String?),
      ctime: $checkedConvert(
        'ctime',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      description: $checkedConvert('description', (v) => v as String?),
      keywords: $checkedConvert(
        'keywords',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      lastUpdateTs: $checkedConvert(
        'last_update_ts',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      mid: $checkedConvert(
        'mid',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      mtime: $checkedConvert(
        'mtime',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      name: $checkedConvert('name', (v) => v as String?),
      rawKeywords: $checkedConvert('raw_keywords', (v) => v as String?),
      seriesId: $checkedConvert(
        'series_id',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      state: $checkedConvert(
        'state',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      total: $checkedConvert(
        'total',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'lastUpdateTs': 'last_update_ts',
    'rawKeywords': 'raw_keywords',
    'seriesId': 'series_id',
  },
);

NetworkBiliPlaylistVideoItem _$NetworkBiliPlaylistVideoItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkBiliPlaylistVideoItem',
  json,
  ($checkedConvert) {
    final val = NetworkBiliPlaylistVideoItem(
      aid: $checkedConvert('aid', (v) => (v as num).toInt()),
      bvid: $checkedConvert('bvid', (v) => v as String),
      attribute: $checkedConvert(
        'attribute',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      author: $checkedConvert('author', (v) => v as String?),
      comment: $checkedConvert(
        'comment',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      copyright: $checkedConvert('copyright', (v) => v as String?),
      created: $checkedConvert(
        'created',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      ctime: $checkedConvert(
        'ctime',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      description: $checkedConvert('description', (v) => v as String?),
      duration: $checkedConvert(
        'duration',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      elecArcBadge: $checkedConvert('elec_arc_badge', (v) => v as String?),
      elecArcType: $checkedConvert(
        'elec_arc_type',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      enableVt: $checkedConvert(
        'enable_vt',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      hideClick: $checkedConvert('hide_click', (v) => v as bool?),
      interactiveVideo: $checkedConvert('interactive_video', (v) => v as bool?),
      isAvoided: $checkedConvert(
        'is_avoided',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      isChargingArc: $checkedConvert('is_charging_arc', (v) => v as bool?),
      isLessonFinished: $checkedConvert(
        'is_lesson_finished',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      isLessonVideo: $checkedConvert(
        'is_lesson_video',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      isLivePlayback: $checkedConvert(
        'is_live_playback',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      isPay: $checkedConvert(
        'is_pay',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      isSelfView: $checkedConvert('is_self_view', (v) => v as bool?),
      isSteinsGate: $checkedConvert(
        'is_steins_gate',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      isUnionVideo: $checkedConvert(
        'is_union_video',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      jumpUrl: $checkedConvert('jump_url', (v) => v as String?),
      length: $checkedConvert('length', (v) => v as String?),
      lessonUpdateInfo: $checkedConvert(
        'lesson_update_info',
        (v) => v as String?,
      ),
      meta: $checkedConvert(
        'meta',
        (v) => v == null
            ? null
            : NetworkBiliPlaylistVideoMeta.fromJson(v as Map<String, dynamic>),
      ),
      mid: $checkedConvert(
        'mid',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      pic: $checkedConvert('pic', (v) => v as String?),
      play: $checkedConvert(
        'play',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      playbackPosition: $checkedConvert(
        'playback_position',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      pubdate: $checkedConvert(
        'pubdate',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      review: $checkedConvert(
        'review',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      seasonId: $checkedConvert(
        'season_id',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      state: $checkedConvert(
        'state',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      subtitle: $checkedConvert('subtitle', (v) => v as String?),
      title: $checkedConvert('title', (v) => v as String?),
      typeid: $checkedConvert(
        'typeid',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      ugcPay: $checkedConvert(
        'ugc_pay',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      videoReview: $checkedConvert(
        'video_review',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      viewSelfType: $checkedConvert(
        'view_self_type',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      vt: $checkedConvert(
        'vt',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      vtDisplay: $checkedConvert('vt_display', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'elecArcBadge': 'elec_arc_badge',
    'elecArcType': 'elec_arc_type',
    'enableVt': 'enable_vt',
    'hideClick': 'hide_click',
    'interactiveVideo': 'interactive_video',
    'isAvoided': 'is_avoided',
    'isChargingArc': 'is_charging_arc',
    'isLessonFinished': 'is_lesson_finished',
    'isLessonVideo': 'is_lesson_video',
    'isLivePlayback': 'is_live_playback',
    'isPay': 'is_pay',
    'isSelfView': 'is_self_view',
    'isSteinsGate': 'is_steins_gate',
    'isUnionVideo': 'is_union_video',
    'jumpUrl': 'jump_url',
    'lessonUpdateInfo': 'lesson_update_info',
    'playbackPosition': 'playback_position',
    'seasonId': 'season_id',
    'ugcPay': 'ugc_pay',
    'videoReview': 'video_review',
    'viewSelfType': 'view_self_type',
    'vtDisplay': 'vt_display',
  },
);

NetworkBiliPlaylistVideoMeta _$NetworkBiliPlaylistVideoMetaFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkBiliPlaylistVideoMeta',
  json,
  ($checkedConvert) {
    final val = NetworkBiliPlaylistVideoMeta(
      attribute: $checkedConvert(
        'attribute',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      cover: $checkedConvert('cover', (v) => v as String?),
      epCount: $checkedConvert(
        'ep_count',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      epNum: $checkedConvert(
        'ep_num',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      firstAid: $checkedConvert(
        'first_aid',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      id: $checkedConvert(
        'id',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      intro: $checkedConvert('intro', (v) => v as String?),
      mid: $checkedConvert(
        'mid',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      ptime: $checkedConvert(
        'ptime',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      signState: $checkedConvert(
        'sign_state',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      stat: $checkedConvert(
        'stat',
        (v) => v == null
            ? null
            : NetworkBiliPlaylistVideoMetaStat.fromJson(
                v as Map<String, dynamic>,
              ),
      ),
      title: $checkedConvert('title', (v) => v as String?),
      show: $checkedConvert(
        'show',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'epCount': 'ep_count',
    'epNum': 'ep_num',
    'firstAid': 'first_aid',
    'signState': 'sign_state',
  },
);

NetworkBiliPlaylistVideoMetaStat _$NetworkBiliPlaylistVideoMetaStatFromJson(
  Map<String, dynamic> json,
) =>
    $checkedCreate('NetworkBiliPlaylistVideoMetaStat', json, ($checkedConvert) {
      final val = NetworkBiliPlaylistVideoMetaStat(
        coin: $checkedConvert(
          'coin',
          (v) => const NullableIntOrStringConverter().fromJson(v),
        ),
        danmaku: $checkedConvert(
          'danmaku',
          (v) => const NullableIntOrStringConverter().fromJson(v),
        ),
        favorite: $checkedConvert(
          'favorite',
          (v) => const NullableIntOrStringConverter().fromJson(v),
        ),
        like: $checkedConvert(
          'like',
          (v) => const NullableIntOrStringConverter().fromJson(v),
        ),
        mtime: $checkedConvert(
          'mtime',
          (v) => const NullableIntOrStringConverter().fromJson(v),
        ),
        reply: $checkedConvert(
          'reply',
          (v) => const NullableIntOrStringConverter().fromJson(v),
        ),
        seasonId: $checkedConvert(
          'season_id',
          (v) => const NullableIntOrStringConverter().fromJson(v),
        ),
        share: $checkedConvert(
          'share',
          (v) => const NullableIntOrStringConverter().fromJson(v),
        ),
        view: $checkedConvert(
          'view',
          (v) => const NullableIntOrStringConverter().fromJson(v),
        ),
        vt: $checkedConvert(
          'vt',
          (v) => const NullableIntOrStringConverter().fromJson(v),
        ),
        vv: $checkedConvert(
          'vv',
          (v) => const NullableIntOrStringConverter().fromJson(v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'seasonId': 'season_id'});

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_bili_user_videos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkBiliUserVideosData _$NetworkBiliUserVideosDataFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkBiliUserVideosData',
  json,
  ($checkedConvert) {
    final val = NetworkBiliUserVideosData(
      list: $checkedConvert(
        'list',
        (v) => v == null
            ? null
            : NetworkBiliUserVideosList.fromJson(v as Map<String, dynamic>),
      ),
      page: $checkedConvert(
        'page',
        (v) => v == null
            ? null
            : NetworkBiliUserVideosPage.fromJson(v as Map<String, dynamic>),
      ),
      episodicButton: $checkedConvert(
        'episodic_button',
        (v) => v == null
            ? null
            : NetworkBiliUserVideosEpisodicButton.fromJson(
                v as Map<String, dynamic>,
              ),
      ),
      isRisk: $checkedConvert('is_risk', (v) => v as bool?),
      gaiaResType: $checkedConvert(
        'gaia_res_type',
        (v) => (v as num?)?.toInt(),
      ),
      gaiaData: $checkedConvert('gaia_data', (v) => v),
    );
    return val;
  },
  fieldKeyMap: const {
    'episodicButton': 'episodic_button',
    'isRisk': 'is_risk',
    'gaiaResType': 'gaia_res_type',
    'gaiaData': 'gaia_data',
  },
);

NetworkBiliUserVideosList _$NetworkBiliUserVideosListFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBiliUserVideosList', json, ($checkedConvert) {
  final val = NetworkBiliUserVideosList(
    slist: $checkedConvert('slist', (v) => v as List<dynamic>?),
    tlist: $checkedConvert(
      'tlist',
      (v) => const NetworkBiliUserVideosTlistConverter().fromJson(v),
    ),
    vlist: $checkedConvert(
      'vlist',
      (v) => const NetworkBiliVideoListConverter().fromJson(v),
    ),
  );
  return val;
});

NetworkBiliUserVideosTlistEntry _$NetworkBiliUserVideosTlistEntryFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBiliUserVideosTlistEntry', json, ($checkedConvert) {
  final val = NetworkBiliUserVideosTlistEntry(
    tid: $checkedConvert(
      'tid',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
    count: $checkedConvert(
      'count',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
    name: $checkedConvert('name', (v) => v as String?),
  );
  return val;
});

NetworkBiliUserVideoItem _$NetworkBiliUserVideoItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkBiliUserVideoItem',
  json,
  ($checkedConvert) {
    final val = NetworkBiliUserVideoItem(
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
      description: $checkedConvert('description', (v) => v as String?),
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
            : NetworkBiliUserVideoMeta.fromJson(v as Map<String, dynamic>),
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
      review: $checkedConvert(
        'review',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      seasonId: $checkedConvert(
        'season_id',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      subtitle: $checkedConvert('subtitle', (v) => v as String?),
      title: $checkedConvert('title', (v) => v as String?),
      typeid: $checkedConvert(
        'typeid',
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
    'videoReview': 'video_review',
    'viewSelfType': 'view_self_type',
    'vtDisplay': 'vt_display',
  },
);

NetworkBiliUserVideoMeta _$NetworkBiliUserVideoMetaFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkBiliUserVideoMeta',
  json,
  ($checkedConvert) {
    final val = NetworkBiliUserVideoMeta(
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
            : NetworkBiliUserVideoMetaStat.fromJson(v as Map<String, dynamic>),
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

NetworkBiliUserVideoMetaStat _$NetworkBiliUserVideoMetaStatFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBiliUserVideoMetaStat', json, ($checkedConvert) {
  final val = NetworkBiliUserVideoMetaStat(
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

NetworkBiliUserVideosPage _$NetworkBiliUserVideosPageFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBiliUserVideosPage', json, ($checkedConvert) {
  final val = NetworkBiliUserVideosPage(
    count: $checkedConvert(
      'count',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
    pn: $checkedConvert(
      'pn',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
    ps: $checkedConvert(
      'ps',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
  );
  return val;
});

NetworkBiliUserVideosEpisodicButton
_$NetworkBiliUserVideosEpisodicButtonFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NetworkBiliUserVideosEpisodicButton', json, (
      $checkedConvert,
    ) {
      final val = NetworkBiliUserVideosEpisodicButton(
        text: $checkedConvert('text', (v) => v as String?),
        uri: $checkedConvert('uri', (v) => v as String?),
      );
      return val;
    });

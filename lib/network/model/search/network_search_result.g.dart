// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Unknown _$UnknownFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Unknown', json, ($checkedConvert) {
      final val = Unknown($checkedConvert('type', (v) => v as String));
      return val;
    });

NetworkArticleSearchResult _$NetworkArticleSearchResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkArticleSearchResult',
  json,
  ($checkedConvert) {
    final val = NetworkArticleSearchResult(
      $checkedConvert('type', (v) => $enumDecode(_$SearchResultTypeEnumMap, v)),
      $checkedConvert('category_id', (v) => (v as num).toInt()),
      $checkedConvert('category_name', (v) => v as String),
      $checkedConvert('comment_url', (v) => v as String),
      $checkedConvert('desc', (v) => v as String),
      $checkedConvert('id', (v) => (v as num).toInt()),
      $checkedConvert(
        'image_urls',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      $checkedConvert('is_comment', (v) => (v as num).toInt()),
      $checkedConvert('is_fold', (v) => v as bool),
      $checkedConvert('is_rk1', (v) => v as bool),
      $checkedConvert('like', (v) => (v as num).toInt()),
      $checkedConvert('mid', (v) => (v as num).toInt()),
      $checkedConvert('pub_time', (v) => (v as num).toInt()),
      $checkedConvert('rank_index', (v) => (v as num).toInt()),
      $checkedConvert('rank_offset', (v) => (v as num).toInt()),
      $checkedConvert('reply', (v) => (v as num).toInt()),
      $checkedConvert('spread_id', (v) => (v as num).toInt()),
      $checkedConvert('sub_type', (v) => (v as num).toInt()),
      $checkedConvert('template_id', (v) => (v as num).toInt()),
      $checkedConvert('title', (v) => HtmlTitle.fromJson(v as String)),
      $checkedConvert('version', (v) => v as String),
      $checkedConvert('view', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'categoryId': 'category_id',
    'categoryName': 'category_name',
    'commentUrl': 'comment_url',
    'imageUrls': 'image_urls',
    'isComment': 'is_comment',
    'isFold': 'is_fold',
    'isRk1': 'is_rk1',
    'pubTime': 'pub_time',
    'rankIndex': 'rank_index',
    'rankOffset': 'rank_offset',
    'spreadId': 'spread_id',
    'subType': 'sub_type',
    'templateId': 'template_id',
  },
);

const _$SearchResultTypeEnumMap = {
  SearchResultType.article: 'article',
  SearchResultType.biliUser: 'bili_user',
  SearchResultType.mediaBangumi: 'media_bangumi',
  SearchResultType.mediaFt: 'media_ft',
  SearchResultType.liveRoom: 'live_room',
  SearchResultType.liveUser: 'live_user',
  SearchResultType.video: 'video',
  SearchResultType.unknown: 'unknown',
};

NetworkBiliUserSearchResult _$NetworkBiliUserSearchResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkBiliUserSearchResult',
  json,
  ($checkedConvert) {
    final val = NetworkBiliUserSearchResult(
      $checkedConvert('type', (v) => $enumDecode(_$SearchResultTypeEnumMap, v)),
      $checkedConvert('mid', (v) => (v as num).toInt()),
      $checkedConvert('uname', (v) => v as String),
      $checkedConvert('usign', (v) => v as String),
      $checkedConvert('fans', (v) => (v as num).toInt()),
      $checkedConvert('videos', (v) => (v as num).toInt()),
      $checkedConvert('upic', (v) => v as String),
      $checkedConvert('face_nft', (v) => (v as num).toInt()),
      $checkedConvert('face_nft_type', (v) => (v as num).toInt()),
      $checkedConvert('verify_info', (v) => v as String),
      $checkedConvert('level', (v) => (v as num).toInt()),
      $checkedConvert('gender', (v) => (v as num).toInt()),
      $checkedConvert('is_upuser', (v) => (v as num).toInt()),
      $checkedConvert('is_live', (v) => (v as num).toInt()),
      $checkedConvert('room_id', (v) => (v as num).toInt()),
      $checkedConvert(
        'res',
        (v) => (v as List<dynamic>)
            .map((e) => NetworkBiliUserRes.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      $checkedConvert(
        'official_verify',
        (v) => NetworkUserOfficialVerify.fromJson(v as Map<String, dynamic>),
      ),
      $checkedConvert('is_senior_member', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'faceNft': 'face_nft',
    'faceNftType': 'face_nft_type',
    'verifyInfo': 'verify_info',
    'isUpuser': 'is_upuser',
    'isLive': 'is_live',
    'roomId': 'room_id',
    'officialVerify': 'official_verify',
    'isSeniorMember': 'is_senior_member',
  },
);

NetworkMediaBangumiSearchResult _$NetworkMediaBangumiSearchResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkMediaBangumiSearchResult',
  json,
  ($checkedConvert) {
    final val = NetworkMediaBangumiSearchResult(
      $checkedConvert('type', (v) => $enumDecode(_$SearchResultTypeEnumMap, v)),
      $checkedConvert('media_id', (v) => (v as num).toInt()),
      $checkedConvert('title', (v) => HtmlTitle.fromJson(v as String)),
      $checkedConvert('org_title', (v) => v as String),
      $checkedConvert('media_type', (v) => (v as num).toInt()),
      $checkedConvert('cv', (v) => v as String),
      $checkedConvert('staff', (v) => v as String),
      $checkedConvert('season_id', (v) => (v as num).toInt()),
      $checkedConvert('is_avid', (v) => v as bool),
      $checkedConvert('hit_epids', (v) => v as String),
      $checkedConvert('season_type', (v) => (v as num).toInt()),
      $checkedConvert('season_type_name', (v) => v as String),
      $checkedConvert('url', (v) => v as String),
      $checkedConvert('button_text', (v) => v as String),
      $checkedConvert('is_selection', (v) => (v as num).toInt()),
      $checkedConvert('cover', (v) => v as String?),
      $checkedConvert('areas', (v) => v as String),
      $checkedConvert('styles', (v) => v as String),
      $checkedConvert('goto_url', (v) => v as String),
      $checkedConvert('desc', (v) => v as String),
      $checkedConvert('pubtime', (v) => (v as num).toInt()),
      $checkedConvert('media_mode', (v) => (v as num).toInt()),
      $checkedConvert(
        'media_score',
        (v) => NetworkMediaScore.fromJson(v as Map<String, dynamic>),
      ),
      $checkedConvert('index_show', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'mediaId': 'media_id',
    'orgTitle': 'org_title',
    'mediaType': 'media_type',
    'seasonId': 'season_id',
    'isAvid': 'is_avid',
    'hitEpids': 'hit_epids',
    'seasonType': 'season_type',
    'seasonTypeName': 'season_type_name',
    'buttonText': 'button_text',
    'isSelection': 'is_selection',
    'gotoUrl': 'goto_url',
    'mediaMode': 'media_mode',
    'mediaScore': 'media_score',
    'indexShow': 'index_show',
  },
);

NetworkMediaFtSearchResult _$NetworkMediaFtSearchResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkMediaFtSearchResult',
  json,
  ($checkedConvert) {
    final val = NetworkMediaFtSearchResult(
      $checkedConvert('type', (v) => $enumDecode(_$SearchResultTypeEnumMap, v)),
      $checkedConvert('media_id', (v) => (v as num).toInt()),
      $checkedConvert('title', (v) => HtmlTitle.fromJson(v as String)),
      $checkedConvert('org_title', (v) => v as String),
      $checkedConvert('media_type', (v) => (v as num).toInt()),
      $checkedConvert('cv', (v) => v as String),
      $checkedConvert('staff', (v) => v as String),
      $checkedConvert('season_id', (v) => (v as num).toInt()),
      $checkedConvert('is_avid', (v) => v as bool),
      $checkedConvert('hit_epids', (v) => v as String),
      $checkedConvert('season_type', (v) => (v as num).toInt()),
      $checkedConvert('season_type_name', (v) => v as String),
      $checkedConvert('url', (v) => v as String),
      $checkedConvert('button_text', (v) => v as String),
      $checkedConvert('is_follow', (v) => (v as num).toInt()),
      $checkedConvert('cover', (v) => v as String),
      $checkedConvert('areas', (v) => v as String),
      $checkedConvert('styles', (v) => v as String),
      $checkedConvert('goto_url', (v) => v as String),
      $checkedConvert('desc', (v) => v as String),
      $checkedConvert('pubtime', (v) => (v as num).toInt()),
      $checkedConvert('media_mode', (v) => (v as num).toInt()),
      $checkedConvert(
        'media_score',
        (v) => NetworkMediaScore.fromJson(v as Map<String, dynamic>),
      ),
      $checkedConvert('index_show', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'mediaId': 'media_id',
    'orgTitle': 'org_title',
    'mediaType': 'media_type',
    'seasonId': 'season_id',
    'isAvid': 'is_avid',
    'hitEpids': 'hit_epids',
    'seasonType': 'season_type',
    'seasonTypeName': 'season_type_name',
    'buttonText': 'button_text',
    'isFollow': 'is_follow',
    'gotoUrl': 'goto_url',
    'mediaMode': 'media_mode',
    'mediaScore': 'media_score',
    'indexShow': 'index_show',
  },
);

NetworkLiveRoomSearchResult _$NetworkLiveRoomSearchResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkLiveRoomSearchResult',
  json,
  ($checkedConvert) {
    final val = NetworkLiveRoomSearchResult(
      $checkedConvert('type', (v) => $enumDecode(_$SearchResultTypeEnumMap, v)),
      $checkedConvert('area', (v) => (v as num).toInt()),
      $checkedConvert('attentions', (v) => (v as num).toInt()),
      $checkedConvert('cate_name', (v) => v as String),
      $checkedConvert('cover', (v) => v as String),
      $checkedConvert('is_live_room_inline', (v) => (v as num).toInt()),
      $checkedConvert('live_status', (v) => (v as num).toInt()),
      $checkedConvert('live_time', (v) => v as String),
      $checkedConvert('online', (v) => (v as num).toInt()),
      $checkedConvert('rank_index', (v) => (v as num).toInt()),
      $checkedConvert('rank_offset', (v) => (v as num).toInt()),
      $checkedConvert('roomid', (v) => (v as num).toInt()),
      $checkedConvert('short_id', (v) => (v as num).toInt()),
      $checkedConvert('style', (v) => (v as num).toInt()),
      $checkedConvert('tags', (v) => v as String),
      $checkedConvert('title', (v) => HtmlTitle.fromJson(v as String)),
      $checkedConvert('uface', (v) => v as String),
      $checkedConvert('uid', (v) => (v as num).toInt()),
      $checkedConvert('uname', (v) => v as String),
      $checkedConvert('user_cover', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'cateName': 'cate_name',
    'isLiveRoomInline': 'is_live_room_inline',
    'liveStatus': 'live_status',
    'liveTime': 'live_time',
    'rankIndex': 'rank_index',
    'rankOffset': 'rank_offset',
    'shortId': 'short_id',
    'userCover': 'user_cover',
  },
);

NetworkLiveUserSearchResult _$NetworkLiveUserSearchResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkLiveUserSearchResult',
  json,
  ($checkedConvert) {
    final val = NetworkLiveUserSearchResult(
      $checkedConvert('type', (v) => $enumDecode(_$SearchResultTypeEnumMap, v)),
      $checkedConvert('area', (v) => (v as num).toInt()),
      $checkedConvert('area_v2_id', (v) => (v as num).toInt()),
      $checkedConvert('attentions', (v) => (v as num).toInt()),
      $checkedConvert('cate_name', (v) => v as String),
      $checkedConvert('id', (v) => (v as num).toInt()),
      $checkedConvert('is_live', (v) => v as bool),
      $checkedConvert('live_status', (v) => (v as num).toInt()),
      $checkedConvert('live_time', (v) => v as String),
      $checkedConvert('rank_index', (v) => (v as num).toInt()),
      $checkedConvert('rank_offset', (v) => (v as num).toInt()),
      $checkedConvert('roomid', (v) => (v as num).toInt()),
      $checkedConvert('tags', (v) => v as String),
      $checkedConvert('uface', (v) => v as String),
      $checkedConvert('uid', (v) => (v as num).toInt()),
      $checkedConvert('uname', (v) => HtmlTitle.fromJson(v as String)),
    );
    return val;
  },
  fieldKeyMap: const {
    'areaV2Id': 'area_v2_id',
    'cateName': 'cate_name',
    'isLive': 'is_live',
    'liveStatus': 'live_status',
    'liveTime': 'live_time',
    'rankIndex': 'rank_index',
    'rankOffset': 'rank_offset',
  },
);

NetworkVideoSearchResult _$NetworkVideoSearchResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkVideoSearchResult',
  json,
  ($checkedConvert) {
    final val = NetworkVideoSearchResult(
      $checkedConvert('type', (v) => $enumDecode(_$SearchResultTypeEnumMap, v)),
      $checkedConvert('id', (v) => (v as num).toInt()),
      $checkedConvert('author', (v) => v as String),
      $checkedConvert('mid', (v) => (v as num).toInt()),
      $checkedConvert('typeid', (v) => v as String),
      $checkedConvert('typename', (v) => v as String),
      $checkedConvert('arcurl', (v) => v as String),
      $checkedConvert('aid', (v) => (v as num).toInt()),
      $checkedConvert('bvid', (v) => v as String),
      $checkedConvert('title', (v) => HtmlTitle.fromJson(v as String)),
      $checkedConvert('description', (v) => v as String),
      $checkedConvert('pic', (v) => v as String),
      $checkedConvert('play', (v) => (v as num).toInt()),
      $checkedConvert('favorites', (v) => (v as num).toInt()),
      $checkedConvert('tag', (v) => v as String),
      $checkedConvert('review', (v) => (v as num).toInt()),
      $checkedConvert('pubdate', (v) => (v as num).toInt()),
      $checkedConvert('senddate', (v) => (v as num).toInt()),
      $checkedConvert('duration', (v) => v as String),
      $checkedConvert('badgepay', (v) => v as bool),
      $checkedConvert('is_union_video', (v) => (v as num).toInt()),
      $checkedConvert('like', (v) => (v as num).toInt()),
      $checkedConvert('upic', (v) => v as String),
      $checkedConvert('corner', (v) => v as String),
      $checkedConvert('cover', (v) => v as String),
      $checkedConvert('desc', (v) => v as String),
      $checkedConvert('url', (v) => v as String),
      $checkedConvert('danmaku', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {'isUnionVideo': 'is_union_video'},
);

_NetworkMediaScore _$NetworkMediaScoreFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_NetworkMediaScore', json, ($checkedConvert) {
      final val = _NetworkMediaScore(
        $checkedConvert('score', (v) => (v as num).toInt()),
        $checkedConvert('user_count', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'userCount': 'user_count'});

_NetworkBiliUserRes _$NetworkBiliUserResFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_NetworkBiliUserRes',
      json,
      ($checkedConvert) {
        final val = _NetworkBiliUserRes(
          $checkedConvert('aid', (v) => (v as num).toInt()),
          $checkedConvert('bvid', (v) => v as String),
          $checkedConvert('title', (v) => v as String),
          $checkedConvert('pubdate', (v) => (v as num).toInt()),
          $checkedConvert('arcurl', (v) => v as String),
          $checkedConvert('pic', (v) => v as String),
          $checkedConvert('play', (v) => v as String),
          $checkedConvert('dm', (v) => (v as num).toInt()),
          $checkedConvert('coin', (v) => (v as num).toInt()),
          $checkedConvert('fav', (v) => (v as num).toInt()),
          $checkedConvert('desc', (v) => v as String),
          $checkedConvert('duration', (v) => v as String),
          $checkedConvert('is_pay', (v) => (v as num).toInt()),
          $checkedConvert('is_union_video', (v) => (v as num).toInt()),
          $checkedConvert('is_charge_video', (v) => (v as num).toInt()),
          $checkedConvert('vt', (v) => (v as num).toInt()),
          $checkedConvert('enable_vt', (v) => (v as num).toInt()),
          $checkedConvert('vt_display', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'isPay': 'is_pay',
        'isUnionVideo': 'is_union_video',
        'isChargeVideo': 'is_charge_video',
        'enableVt': 'enable_vt',
        'vtDisplay': 'vt_display',
      },
    );

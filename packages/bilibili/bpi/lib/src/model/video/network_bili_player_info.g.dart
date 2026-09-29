// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_bili_player_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkBiliPlayerInfo _$NetworkBiliPlayerInfoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkBiliPlayerInfo',
  json,
  ($checkedConvert) {
    final val = NetworkBiliPlayerInfo(
      aid: $checkedConvert('aid', (v) => (v as num).toInt()),
      bvid: $checkedConvert('bvid', (v) => v as String),
      cid: $checkedConvert('cid', (v) => (v as num).toInt()),
      loginMid: $checkedConvert('login_mid', (v) => (v as num?)?.toInt()),
      loginMidHash: $checkedConvert('login_mid_hash', (v) => v as String?),
      isOwner: $checkedConvert('is_owner', (v) => v as bool?),
      name: $checkedConvert('name', (v) => v as String?),
      subtitle: $checkedConvert(
        'subtitle',
        (v) => v == null
            ? null
            : NetworkBiliSubtitleContainer.fromJson(v as Map<String, dynamic>),
      ),
      viewPoints: $checkedConvert(
        'view_points',
        (v) => (v as List<dynamic>?)
            ?.map(
              (e) => NetworkBiliViewPoint.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      bgmInfo: $checkedConvert(
        'bgm_info',
        (v) => v == null
            ? null
            : NetworkBiliBgmInfo.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'loginMid': 'login_mid',
    'loginMidHash': 'login_mid_hash',
    'isOwner': 'is_owner',
    'viewPoints': 'view_points',
    'bgmInfo': 'bgm_info',
  },
);

NetworkBiliSubtitleContainer _$NetworkBiliSubtitleContainerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBiliSubtitleContainer', json, ($checkedConvert) {
  final val = NetworkBiliSubtitleContainer(
    allowSubmit: $checkedConvert('allow_submit', (v) => v as bool?),
    lan: $checkedConvert('lan', (v) => v as String?),
    lanDoc: $checkedConvert('lan_doc', (v) => v as String?),
    subtitles: $checkedConvert(
      'subtitles',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => NetworkBiliSubtitleItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'allowSubmit': 'allow_submit', 'lanDoc': 'lan_doc'});

NetworkBiliSubtitleItem _$NetworkBiliSubtitleItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkBiliSubtitleItem',
  json,
  ($checkedConvert) {
    final val = NetworkBiliSubtitleItem(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      lan: $checkedConvert('lan', (v) => v as String),
      lanDoc: $checkedConvert('lan_doc', (v) => v as String),
      isMachine: $checkedConvert('is_machine', (v) => v as bool?),
      subtitleUrl: $checkedConvert('subtitle_url', (v) => v as String),
      type: $checkedConvert('type', (v) => (v as num?)?.toInt()),
      idStr: $checkedConvert('id_str', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'lanDoc': 'lan_doc',
    'isMachine': 'is_machine',
    'subtitleUrl': 'subtitle_url',
    'idStr': 'id_str',
  },
);

NetworkBiliViewPoint _$NetworkBiliViewPointFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBiliViewPoint', json, ($checkedConvert) {
  final val = NetworkBiliViewPoint(
    type: $checkedConvert('type', (v) => (v as num?)?.toInt()),
    from: $checkedConvert('from', (v) => v as num?),
    to: $checkedConvert('to', (v) => v as num?),
    content: $checkedConvert('content', (v) => v as String?),
    imgUrl: $checkedConvert('img_url', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'imgUrl': 'img_url'});

NetworkBiliBgmInfo _$NetworkBiliBgmInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'NetworkBiliBgmInfo',
      json,
      ($checkedConvert) {
        final val = NetworkBiliBgmInfo(
          musicId: $checkedConvert('music_id', (v) => v as String?),
          musicTitle: $checkedConvert('music_title', (v) => v as String?),
          jumpUrl: $checkedConvert('jump_url', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'musicId': 'music_id',
        'musicTitle': 'music_title',
        'jumpUrl': 'jump_url',
      },
    );

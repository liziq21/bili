// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_live_room_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkLiveRoomDetail _$NetworkLiveRoomDetailFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkLiveRoomDetail',
  json,
  ($checkedConvert) {
    final val = NetworkLiveRoomDetail(
      roomInfo: $checkedConvert(
        'room_info',
        (v) => NetworkLiveRoomInfo.fromJson(v as Map<String, dynamic>),
      ),
      anchorInfo: $checkedConvert(
        'anchor_info',
        (v) => v == null
            ? null
            : NetworkLiveAnchorInfo.fromJson(v as Map<String, dynamic>),
      ),
      watchedShow: $checkedConvert(
        'watched_show',
        (v) => v == null
            ? null
            : NetworkLiveWatchedShow.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'roomInfo': 'room_info',
    'anchorInfo': 'anchor_info',
    'watchedShow': 'watched_show',
  },
);

NetworkLiveRoomInfo _$NetworkLiveRoomInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'NetworkLiveRoomInfo',
      json,
      ($checkedConvert) {
        final val = NetworkLiveRoomInfo(
          roomId: $checkedConvert('room_id', (v) => (v as num).toInt()),
          uid: $checkedConvert('uid', (v) => (v as num).toInt()),
          title: $checkedConvert('title', (v) => v as String),
          cover: $checkedConvert('cover', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String?),
          liveStatus: $checkedConvert('live_status', (v) => (v as num).toInt()),
          liveStartTime: $checkedConvert(
            'live_start_time',
            (v) => (v as num?)?.toInt(),
          ),
          areaId: $checkedConvert('area_id', (v) => (v as num?)?.toInt()),
          areaName: $checkedConvert('area_name', (v) => v as String?),
          parentAreaId: $checkedConvert(
            'parent_area_id',
            (v) => (v as num?)?.toInt(),
          ),
          parentAreaName: $checkedConvert(
            'parent_area_name',
            (v) => v as String?,
          ),
          online: $checkedConvert('online', (v) => (v as num?)?.toInt()),
          keyframe: $checkedConvert('keyframe', (v) => v as String?),
          background: $checkedConvert('background', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'roomId': 'room_id',
        'liveStatus': 'live_status',
        'liveStartTime': 'live_start_time',
        'areaId': 'area_id',
        'areaName': 'area_name',
        'parentAreaId': 'parent_area_id',
        'parentAreaName': 'parent_area_name',
      },
    );

NetworkLiveAnchorInfo _$NetworkLiveAnchorInfoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkLiveAnchorInfo',
  json,
  ($checkedConvert) {
    final val = NetworkLiveAnchorInfo(
      baseInfo: $checkedConvert(
        'base_info',
        (v) => v == null
            ? null
            : NetworkLiveAnchorBaseInfo.fromJson(v as Map<String, dynamic>),
      ),
      relationInfo: $checkedConvert(
        'relation_info',
        (v) => v == null
            ? null
            : NetworkLiveAnchorRelationInfo.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'baseInfo': 'base_info', 'relationInfo': 'relation_info'},
);

NetworkLiveAnchorBaseInfo _$NetworkLiveAnchorBaseInfoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkLiveAnchorBaseInfo', json, ($checkedConvert) {
  final val = NetworkLiveAnchorBaseInfo(
    uname: $checkedConvert('uname', (v) => v as String),
    face: $checkedConvert('face', (v) => v as String),
    officialInfo: $checkedConvert(
      'official_info',
      (v) => v == null
          ? null
          : NetworkLiveOfficialInfo.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
}, fieldKeyMap: const {'officialInfo': 'official_info'});

NetworkLiveOfficialInfo _$NetworkLiveOfficialInfoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkLiveOfficialInfo', json, ($checkedConvert) {
  final val = NetworkLiveOfficialInfo(
    role: $checkedConvert('role', (v) => (v as num?)?.toInt()),
    title: $checkedConvert('title', (v) => v as String?),
    desc: $checkedConvert('desc', (v) => v as String?),
  );
  return val;
});

NetworkLiveAnchorRelationInfo _$NetworkLiveAnchorRelationInfoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkLiveAnchorRelationInfo', json, ($checkedConvert) {
  final val = NetworkLiveAnchorRelationInfo(
    attention: $checkedConvert('attention', (v) => (v as num?)?.toInt()),
  );
  return val;
});

NetworkLiveWatchedShow _$NetworkLiveWatchedShowFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkLiveWatchedShow', json, ($checkedConvert) {
  final val = NetworkLiveWatchedShow(
    num: $checkedConvert('num', (v) => (v as num?)?.toInt()),
    textSmall: $checkedConvert('text_small', (v) => v as String?),
    textLarge: $checkedConvert('text_large', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'textSmall': 'text_small', 'textLarge': 'text_large'});

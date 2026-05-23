// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_live_room_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NetworkLiveRoomSearchResult _$NetworkLiveRoomSearchResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_NetworkLiveRoomSearchResult',
  json,
  ($checkedConvert) {
    final val = _NetworkLiveRoomSearchResult(
      area: $checkedConvert('area', (v) => (v as num).toInt()),
      attentions: $checkedConvert('attentions', (v) => (v as num).toInt()),
      cateName: $checkedConvert('cate_name', (v) => v as String),
      cover: $checkedConvert('cover', (v) => v as String),
      isLiveRoomInline: $checkedConvert(
        'is_live_room_inline',
        (v) => (v as num).toInt(),
      ),
      liveStatus: $checkedConvert('live_status', (v) => (v as num).toInt()),
      liveTime: $checkedConvert('live_time', (v) => v as String),
      online: $checkedConvert('online', (v) => (v as num).toInt()),
      rankIndex: $checkedConvert('rank_index', (v) => (v as num).toInt()),
      rankOffset: $checkedConvert('rank_offset', (v) => (v as num).toInt()),
      roomid: $checkedConvert('roomid', (v) => (v as num).toInt()),
      shortId: $checkedConvert('short_id', (v) => (v as num).toInt()),
      style: $checkedConvert('style', (v) => (v as num).toInt()),
      tags: $checkedConvert('tags', (v) => v as String),
      title: $checkedConvert('title', (v) => HtmlTitle.fromJson(v)),
      uface: $checkedConvert('uface', (v) => v as String),
      uid: $checkedConvert('uid', (v) => (v as num).toInt()),
      uname: $checkedConvert('uname', (v) => v as String),
      userCover: $checkedConvert('user_cover', (v) => v as String),
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

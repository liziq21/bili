// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_live_user_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NetworkLiveUserSearchResult _$NetworkLiveUserSearchResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_NetworkLiveUserSearchResult',
  json,
  ($checkedConvert) {
    final val = _NetworkLiveUserSearchResult(
      area: $checkedConvert('area', (v) => (v as num).toInt()),
      areaV2Id: $checkedConvert('area_v2_id', (v) => (v as num).toInt()),
      attentions: $checkedConvert('attentions', (v) => (v as num).toInt()),
      cateName: $checkedConvert('cate_name', (v) => v as String),
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      isLive: $checkedConvert('is_live', (v) => v as bool),
      liveStatus: $checkedConvert('live_status', (v) => (v as num).toInt()),
      liveTime: $checkedConvert('live_time', (v) => v as String),
      rankIndex: $checkedConvert('rank_index', (v) => (v as num).toInt()),
      rankOffset: $checkedConvert('rank_offset', (v) => (v as num).toInt()),
      roomid: $checkedConvert('roomid', (v) => (v as num).toInt()),
      tags: $checkedConvert('tags', (v) => v as String),
      uface: $checkedConvert('uface', (v) => v as String),
      uid: $checkedConvert('uid', (v) => (v as num).toInt()),
      uname: $checkedConvert('uname', (v) => HtmlTitle.fromJson(v)),
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

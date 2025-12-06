// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_bili_user_res.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NetworkBiliUserRes _$NetworkBiliUserResFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_NetworkBiliUserRes',
      json,
      ($checkedConvert) {
        final val = _NetworkBiliUserRes(
          aid: $checkedConvert('aid', (v) => (v as num).toInt()),
          bvid: $checkedConvert('bvid', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          pubdate: $checkedConvert('pubdate', (v) => (v as num).toInt()),
          arcurl: $checkedConvert('arcurl', (v) => v as String),
          pic: $checkedConvert('pic', (v) => v as String),
          play: $checkedConvert('play', (v) => v as String),
          dm: $checkedConvert('dm', (v) => (v as num).toInt()),
          coin: $checkedConvert('coin', (v) => (v as num).toInt()),
          fav: $checkedConvert('fav', (v) => (v as num).toInt()),
          desc: $checkedConvert('desc', (v) => v as String),
          duration: $checkedConvert('duration', (v) => v as String),
          isPay: $checkedConvert('is_pay', (v) => (v as num).toInt()),
          isUnionVideo: $checkedConvert(
            'is_union_video',
            (v) => (v as num).toInt(),
          ),
          isChargeVideo: $checkedConvert(
            'is_charge_video',
            (v) => (v as num).toInt(),
          ),
          vt: $checkedConvert('vt', (v) => (v as num).toInt()),
          enableVt: $checkedConvert('enable_vt', (v) => (v as num).toInt()),
          vtDisplay: $checkedConvert('vt_display', (v) => v as String),
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

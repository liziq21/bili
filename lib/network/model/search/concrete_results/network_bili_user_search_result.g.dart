// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_bili_user_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NetworkBiliUserSearchResult _$NetworkBiliUserSearchResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_NetworkBiliUserSearchResult',
  json,
  ($checkedConvert) {
    final val = _NetworkBiliUserSearchResult(
      mid: $checkedConvert('mid', (v) => (v as num).toInt()),
      uname: $checkedConvert('uname', (v) => v as String),
      usign: $checkedConvert('usign', (v) => v as String),
      fans: $checkedConvert('fans', (v) => (v as num).toInt()),
      videos: $checkedConvert('videos', (v) => (v as num).toInt()),
      upic: $checkedConvert('upic', (v) => v as String),
      faceNft: $checkedConvert('face_nft', (v) => (v as num).toInt()),
      faceNftType: $checkedConvert('face_nft_type', (v) => (v as num).toInt()),
      verifyInfo: $checkedConvert('verify_info', (v) => v as String),
      level: $checkedConvert('level', (v) => (v as num).toInt()),
      gender: $checkedConvert('gender', (v) => (v as num).toInt()),
      isUpuser: $checkedConvert('is_upuser', (v) => (v as num).toInt()),
      isLive: $checkedConvert('is_live', (v) => (v as num).toInt()),
      roomId: $checkedConvert('room_id', (v) => (v as num).toInt()),
      res: $checkedConvert(
        'res',
        (v) => (v as List<dynamic>)
            .map((e) => NetworkBiliUserRes.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      officialVerify: $checkedConvert(
        'official_verify',
        (v) => NetworkUserOfficialVerify.fromJson(v as Map<String, dynamic>),
      ),
      isSeniorMember: $checkedConvert(
        'is_senior_member',
        (v) => (v as num).toInt(),
      ),
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

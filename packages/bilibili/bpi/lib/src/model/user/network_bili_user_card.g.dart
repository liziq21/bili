// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_bili_user_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkBiliUserCardData _$NetworkBiliUserCardDataFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkBiliUserCardData',
  json,
  ($checkedConvert) {
    final val = NetworkBiliUserCardData(
      card: $checkedConvert(
        'card',
        (v) => NetworkBiliUserCardDetail.fromJson(v as Map<String, dynamic>),
      ),
      following: $checkedConvert('following', (v) => v as bool?),
      archiveCount: $checkedConvert(
        'archive_count',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      articleCount: $checkedConvert(
        'article_count',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      follower: $checkedConvert(
        'follower',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'archiveCount': 'archive_count',
    'articleCount': 'article_count',
  },
);

NetworkBiliUserCardDetail _$NetworkBiliUserCardDetailFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkBiliUserCardDetail',
  json,
  ($checkedConvert) {
    final val = NetworkBiliUserCardDetail(
      mid: $checkedConvert(
        'mid',
        (v) => const IntOrStringConverter().fromJson(v as Object),
      ),
      name: $checkedConvert('name', (v) => v as String),
      face: $checkedConvert('face', (v) => v as String?),
      sign: $checkedConvert('sign', (v) => v as String?),
      sex: $checkedConvert('sex', (v) => v as String?),
      fans: $checkedConvert(
        'fans',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      friend: $checkedConvert(
        'friend',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      attention: $checkedConvert(
        'attention',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      levelInfo: $checkedConvert(
        'level_info',
        (v) => v == null
            ? null
            : NetworkBiliUserCardLevelInfo.fromJson(v as Map<String, dynamic>),
      ),
      officialVerify: $checkedConvert(
        'official_verify',
        (v) => v == null
            ? null
            : NetworkBiliUserCardOfficialVerify.fromJson(
                v as Map<String, dynamic>,
              ),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'levelInfo': 'level_info',
    'officialVerify': 'official_verify',
  },
);

NetworkBiliUserCardLevelInfo _$NetworkBiliUserCardLevelInfoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkBiliUserCardLevelInfo',
  json,
  ($checkedConvert) {
    final val = NetworkBiliUserCardLevelInfo(
      currentLevel: $checkedConvert(
        'current_level',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      currentMin: $checkedConvert(
        'current_min',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      currentExp: $checkedConvert(
        'current_exp',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      nextExp: $checkedConvert(
        'next_exp',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'currentLevel': 'current_level',
    'currentMin': 'current_min',
    'currentExp': 'current_exp',
    'nextExp': 'next_exp',
  },
);

NetworkBiliUserCardOfficialVerify _$NetworkBiliUserCardOfficialVerifyFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBiliUserCardOfficialVerify', json, (
  $checkedConvert,
) {
  final val = NetworkBiliUserCardOfficialVerify(
    type: $checkedConvert('type', (v) => (v as num?)?.toInt()),
    desc: $checkedConvert('desc', (v) => v as String?),
  );
  return val;
});

NetworkBiliUserCardResponse _$NetworkBiliUserCardResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBiliUserCardResponse', json, ($checkedConvert) {
  final val = NetworkBiliUserCardResponse(
    code: $checkedConvert('code', (v) => (v as num).toInt()),
    message: $checkedConvert('message', (v) => v as String),
    data: $checkedConvert(
      'data',
      (v) => v == null
          ? null
          : NetworkBiliUserCardData.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

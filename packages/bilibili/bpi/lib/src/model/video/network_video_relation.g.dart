// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_video_relation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkVideoRelation _$NetworkVideoRelationFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkVideoRelation', json, ($checkedConvert) {
  final val = NetworkVideoRelation(
    attention: $checkedConvert('attention', (v) => v as bool?),
    favorite: $checkedConvert('favorite', (v) => v as bool?),
    seasonFav: $checkedConvert('season_fav', (v) => v as bool?),
    like: $checkedConvert('like', (v) => v as bool?),
    dislike: $checkedConvert('dislike', (v) => v as bool?),
    coin: $checkedConvert('coin', (v) => v as num?),
  );
  return val;
}, fieldKeyMap: const {'seasonFav': 'season_fav'});

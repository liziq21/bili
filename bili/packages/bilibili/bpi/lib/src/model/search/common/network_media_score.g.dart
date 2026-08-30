// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_media_score.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkMediaScore _$NetworkMediaScoreFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NetworkMediaScore', json, ($checkedConvert) {
      final val = NetworkMediaScore(
        score: $checkedConvert('score', (v) => (v as num).toInt()),
        userCount: $checkedConvert('user_count', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'userCount': 'user_count'});

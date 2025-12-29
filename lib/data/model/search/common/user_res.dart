import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_bili_user_res.freezed.dart';

@freezed
abstract class UserRes with _$UserRes {
  const factory UserRes({
    required int aid,
    required String bvid,
    required String title,
    required int pubdate,
    required String arcurl,
    required String pic,
    required String play,
    required int dm,
    required int coin,
    required int fav,
    required String desc,
    required String duration,
    required int isPay,
    required int isUnionVideo,
    required int isChargeVideo,
    required int vt,
    required int enableVt,
    required String vtDisplay,
  }) = UserRes;
}

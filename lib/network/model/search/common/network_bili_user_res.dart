import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_bili_user_res.freezed.dart';
part 'network_bili_user_res.g.dart';

@freezed
abstract class NetworkBiliUserRes with _$NetworkBiliUserRes {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory NetworkBiliUserRes({
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
  }) = _NetworkBiliUserRes;
  
  factory NetworkBiliUserRes.fromJson(Map<String, dynamic> json)
    => _$NetworkBiliUserResFromJson(json);
}

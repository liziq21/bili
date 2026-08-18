import 'package:json_annotation/json_annotation.dart';

part 'network_bili_user_res.g.dart';

@JsonSerializable(fieldRename: .snake, createToJson: false)
class const NetworkBiliUserRes({
  required final int aid,
  required final String bvid,
  required final String title,
  required final int pubdate,
  required final String arcurl,
  required final String pic,
  required final int play, //String
  required final int dm,
  required final int coin,
  required final int fav,
  required final String desc,
  required final String duration,
  required final int isPay,
  required final int isUnionVideo,
  required final int isChargeVideo,
  required final int vt,
  required final int enableVt,
  required final String vtDisplay,
}) {
  factory NetworkBiliUserRes.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliUserResFromJson(json);
}

// @freezed
// abstract class NetworkBiliUserRes with _$NetworkBiliUserRes {
//   @JsonSerializable(fieldRename: .snake)
//   const factory NetworkBiliUserRes({
//     required int aid,
//     required String bvid,
//     required String title,
//     required int pubdate,
//     required String arcurl,
//     required String pic,
//     required int play, //String
//     required int dm,
//     required int coin,
//     required int fav,
//     required String desc,
//     required String duration,
//     required int isPay,
//     required int isUnionVideo,
//     required int isChargeVideo,
//     required int vt,
//     required int enableVt,
//     required String vtDisplay,
//   }) = _NetworkBiliUserRes;
//
//   factory NetworkBiliUserRes.fromJson(Map<String, dynamic> json) =>
//       _$NetworkBiliUserResFromJson(json);
// }

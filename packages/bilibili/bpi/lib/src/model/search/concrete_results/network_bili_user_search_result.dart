import 'package:json_annotation/json_annotation.dart';

import '../../user/common/network_user_official_verify.dart';
import '../common/network_bili_user_res.dart';

part 'network_bili_user_search_result.g.dart';

@JsonSerializable(fieldRename: .snake, createToJson: false)
class const NetworkBiliUserSearchResult({
  required final int mid,
  required final String uname,
  required final String usign,
  required final int fans,
  required final int videos,
  required final String upic,
  required final int faceNft,
  required final int faceNftType,
  required final String verifyInfo,
  required final int level,
  required final int gender,
  required final int isUpuser,
  required final int isLive,
  required final int roomId,
  required final List<NetworkBiliUserRes> res,
  required final NetworkUserOfficialVerify officialVerify,
  required final int isSeniorMember,
}) {
  factory NetworkBiliUserSearchResult.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliUserSearchResultFromJson(json);
}
// @freezed
// abstract class NetworkBiliUserSearchResult with _$NetworkBiliUserSearchResult {
//   @JsonSerializable(fieldRename: .snake)
//   const factory NetworkBiliUserSearchResult({
//     required int mid,
//     required String uname,
//     required String usign,
//     required int fans,
//     required int videos,
//     required String upic,
//     required int faceNft,
//     required int faceNftType,
//     required String verifyInfo,
//     required int level,
//     required int gender,
//     required int isUpuser,
//     required int isLive,
//     required int roomId,
//     required List<NetworkBiliUserRes> res,
//     required NetworkUserOfficialVerify officialVerify,
//     required int isSeniorMember,
//   }) = _NetworkBiliUserSearchResult;
//
//   factory NetworkBiliUserSearchResult.fromJson(Map<String, dynamic> json) =>
//       _$NetworkBiliUserSearchResultFromJson(json);
// }


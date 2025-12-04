import 'package:freezed_annotation/freezed_annotation.dart';
import '../../user/common/network_user_official_verify.dart';
import '../common/network_bili_user_res.dart';

part 'network_bili_user_search_result.freezed.dart';
part 'network_bili_user_search_result.g.dart';

@freezed
class NetworkBiliUserSearchResult with _$NetworkBiliUserSearchResult {
  @JsonSerializable(fieldRename: .snake)
  const factory NetworkBiliUserSearchResult({
    required int mid,
    required String uname,
    required String usign,
    required int fans,
    required int videos,
    required String upic,
    required int faceNft,
    required int faceNftType,
    required String verifyInfo,
    required int level,
    required int gender,
    required int isUpuser,
    required int isLive,
    required int roomId,
    required List<NetworkBiliUserRes> res,
    required NetworkUserOfficialVerify officialVerify,
    required int isSeniorMember,
  }) = _NetworkBiliUserSearchResult;

  factory NetworkBiliUserSearchResult.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliUserSearchResultFromJson(json);
}
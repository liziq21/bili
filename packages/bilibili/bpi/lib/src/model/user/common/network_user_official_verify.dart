import 'package:json_annotation/json_annotation.dart';

part 'network_user_official_verify.g.dart';

@JsonSerializable(createToJson: false)
class const NetworkUserOfficialVerify({
  required final int type,
  required final String desc,
}) {
  factory NetworkUserOfficialVerify.fromJson(Map<String, dynamic> json) =>
      _$NetworkUserOfficialVerifyFromJson(json);
}

// @freezed
// abstract class NetworkUserOfficialVerify with _$NetworkUserOfficialVerify {
//   const factory NetworkUserOfficialVerify({
//     required int type,
//     required String desc,
//   }) = _NetworkUserOfficialVerify;
//
//   factory NetworkUserOfficialVerify.fromJson(Map<String, dynamic> json)
//     => _$NetworkUserOfficialVerifyFromJson(json);
// }

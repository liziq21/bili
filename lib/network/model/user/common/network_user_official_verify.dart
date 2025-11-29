import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_user_official_verify.freezed.dart';
part 'network_user_official_verify.g.dart';

@freezed
abstract class NetworkUserOfficialVerify with _$NetworkUserOfficialVerify {
  const factory NetworkUserOfficialVerify({
    required int type,
    required String desc,
  }) = _NetworkUserOfficialVerify;

  factory NetworkUserOfficialVerify.fromJson(Map<String, dynamic> json)
    => _$NetworkUserOfficialVerifyFromJson(json);
}
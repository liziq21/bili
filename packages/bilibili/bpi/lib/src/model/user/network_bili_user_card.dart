import 'package:json_annotation/json_annotation.dart';

import '../../converter/int_or_string_converter.dart';

part 'network_bili_user_card.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliUserCardData({
  required final NetworkBiliUserCardDetail card,
  final bool? following,
  final int? archiveCount,
  final int? articleCount,
  final int? follower,
}) {
  factory NetworkBiliUserCardData.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliUserCardDataFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliUserCardDetail({
  @IntOrStringConverter() required final String mid,
  required final String name,
  final String? face,
  final String? sign,
  final String? sex,
  final int? fans,
  final int? friend,
  final int? attention,
  final NetworkBiliUserCardLevelInfo? levelInfo,
  final NetworkBiliUserCardOfficialVerify? officialVerify,
}) {
  factory NetworkBiliUserCardDetail.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliUserCardDetailFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliUserCardLevelInfo({
  final int? currentLevel,
  final int? currentMin,
  final int? currentExp,
  final int? nextExp,
}) {
  factory NetworkBiliUserCardLevelInfo.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliUserCardLevelInfoFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliUserCardOfficialVerify({final int? type, final String? desc}) {
  factory NetworkBiliUserCardOfficialVerify.fromJson(
    Map<String, dynamic> json,
  ) => _$NetworkBiliUserCardOfficialVerifyFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliUserCardResponse({
  required final int code,
  required final String message,
  final NetworkBiliUserCardData? data,
}) {
  factory NetworkBiliUserCardResponse.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliUserCardResponseFromJson(json);
}

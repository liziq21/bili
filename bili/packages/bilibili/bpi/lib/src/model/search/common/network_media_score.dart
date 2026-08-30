import 'package:json_annotation/json_annotation.dart';

part 'network_media_score.g.dart';

@JsonSerializable(fieldRename: .snake, createToJson: false)
class const NetworkMediaScore({
  required final int score,
  required final int userCount,
}) {
  factory NetworkMediaScore.fromJson(Map<String, dynamic> json) =>
      _$NetworkMediaScoreFromJson(json);
}
// @freezed
// abstract class NetworkMediaScore with _$NetworkMediaScore{
//   @JsonSerializable(fieldRename: .snake)
//   const factory NetworkMediaScore({
//     required int score,
//     required int userCount,
//   }) = _NetworkMediaScore;
//
//   factory NetworkMediaScore.fromJson(Map<String, dynamic> json)
//     => _$NetworkMediaScoreFromJson(json);
// }

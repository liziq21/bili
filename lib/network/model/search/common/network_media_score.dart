import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_media_score.freezed.dart';
part 'network_media_score.g.dart';

@freezed
abstract class NetworkMediaScore with _$NetworkMediaScore{
  @JsonSerializable(fieldRename: .snake)
  const factory NetworkMediaScore({
    required int score,
    required int userCount,
  }) = _NetworkMediaScore;
  
  factory NetworkMediaScore.fromJson(Map<String, dynamic> json)
    => _$NetworkMediaScoreFromJson(json);
}


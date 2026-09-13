import 'package:json_annotation/json_annotation.dart';

part 'network_video_relation.g.dart';

/// 视频与当前用户交互状态模型 (如点赞、收藏、投币、关注)
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkVideoRelation({
  final bool? attention,
  final bool? favorite,
  final bool? seasonFav,
  final bool? like,
  final bool? dislike,
  final num? coin,
}) {
  factory NetworkVideoRelation.fromJson(Map<String, dynamic> json) =>
      _$NetworkVideoRelationFromJson(json);
}

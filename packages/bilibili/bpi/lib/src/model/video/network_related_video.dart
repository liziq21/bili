import 'package:json_annotation/json_annotation.dart';
import 'video_detail_data.dart';

part 'network_related_video.g.dart';

/// 相关/推荐视频列表响应包裹类
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkRelatedVideosList({
  @JsonKey(name: 'items') required final List<NetworkRelatedVideo> items,
}) {
  factory NetworkRelatedVideosList.fromJson(Map<String, dynamic> json) =>
      _$NetworkRelatedVideosListFromJson(json);
}

/// 相关/推荐视频数据模型 (/x/web-interface/archive/related)
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkRelatedVideo({
  required final int aid,
  required final String bvid,
  final int? cid,
  final String? title,
  final String? pic,
  final String? desc,
  final int? duration,
  final int? pubdate,
  final int? ctime,
  final Owner? owner,
  final VideoStat? stat,
  final Dimension? dimension,
  final String? firstFrame,
  final String? shortLink,
  final String? redirectUrl,
}) {
  factory NetworkRelatedVideo.fromJson(Map<String, dynamic> json) =>
      _$NetworkRelatedVideoFromJson(json);
}

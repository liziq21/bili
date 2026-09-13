import 'package:json_annotation/json_annotation.dart';

import '../common/html_title.dart';

part 'network_video_search_result.g.dart';

@JsonSerializable(fieldRename: .snake, createToJson: false)
class const NetworkVideoSearchResult({
  required final int id,
  required final String author,
  required final int mid,
  required final String typeid,
  required final String typename,
  required final String arcurl,
  required final int aid,
  required final String bvid,
  required final HtmlTitle title,
  required final String description,
  required final String pic,
  required final int play,
  required final int favorites,
  required final String tag,
  required final int review,
  required final int pubdate,
  required final int senddate,
  required final String duration,
  required final bool badgepay,
  required final int isUnionVideo,
  required final int like,
  required final String upic,
  required final String corner,
  required final String cover,
  required final String desc,
  required final String url,
  required final int danmaku,
}) {
  factory NetworkVideoSearchResult.fromJson(Map<String, dynamic> json) =>
      _$NetworkVideoSearchResultFromJson(json);
}

// @freezed
// abstract class NetworkVideoSearchResult with _$NetworkVideoSearchResult {
//   @JsonSerializable(fieldRename: .snake)
//   const factory NetworkVideoSearchResult({
//     required int id,
//     required String author,
//     required int mid,
//     required String typeid,
//     required String typename,
//     required String arcurl,
//     required int aid,
//     required String bvid,
//     required HtmlTitle title,
//     required String description,
//     required String pic,
//     required int play,
//     required int favorites,
//     required String tag,
//     required int review,
//     required int pubdate,
//     required int senddate,
//     required String duration,
//     required bool badgepay,
//     required int isUnionVideo,
//     required int like,
//     required String upic,
//     required String corner,
//     required String cover,
//     required String desc,
//     required String url,
//     required int danmaku,
//   }) = _NetworkVideoSearchResult;
//
//   factory NetworkVideoSearchResult.fromJson(Map<String, dynamic> json) =>
//       _$NetworkVideoSearchResultFromJson(json);
// }

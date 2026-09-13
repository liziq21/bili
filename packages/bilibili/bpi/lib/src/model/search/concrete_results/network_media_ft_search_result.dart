import 'package:json_annotation/json_annotation.dart';

import '../common/html_title.dart';
import '../common/network_media_score.dart';

part 'network_media_ft_search_result.g.dart';

@JsonSerializable(fieldRename: .snake, createToJson: false)
class const NetworkMediaFtSearchResult({
  required final int mediaId,
  required final HtmlTitle title,
  required final String orgTitle,
  required final int mediaType,
  required final String cv,
  required final String staff,
  required final int seasonId,
  required final bool isAvid,
  required final String hitEpids,
  required final int seasonType,
  required final String seasonTypeName,
  required final String url,
  required final String buttonText,
  required final int isSelection,
  required final String cover,
  required final String areas,
  required final String styles,
  required final String gotoUrl,
  required final String desc,
  required final int pubtime,
  required final int mediaMode,
  required final NetworkMediaScore mediaScore,
  required final String indexShow,
}) {
  factory NetworkMediaFtSearchResult.fromJson(Map<String, dynamic> json) =>
      _$NetworkMediaFtSearchResultFromJson(json);
}

// @freezed
// abstract class NetworkMediaFtSearchResult with _$NetworkMediaFtSearchResult {
//   @JsonSerializable(fieldRename: .snake)
//   const factory NetworkMediaFtSearchResult({
//     required int mediaId,
//     required HtmlTitle title,
//     required String orgTitle,
//     required int mediaType,
//     required String cv,
//     required String staff,
//     required int seasonId,
//     required bool isAvid,
//     required String hitEpids,
//     required int seasonType,
//     required String seasonTypeName,
//     required String url,
//     required String buttonText,
//     required int isSelection,
//     required String cover,
//     required String areas,
//     required String styles,
//     required String gotoUrl,
//     required String desc,
//     required int pubtime,
//     required int mediaMode,
//     required NetworkMediaScore mediaScore,
//     required String indexShow,
//   }) = _NetworkMediaFtSearchResult;
//
//   factory NetworkMediaFtSearchResult.fromJson(Map<String, dynamic> json) =>
//       _$NetworkMediaFtSearchResultFromJson(json);
// }

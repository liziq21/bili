import 'package:json_annotation/json_annotation.dart';

import '../common/html_title.dart';

part 'network_article_search_result.g.dart';

@JsonSerializable(fieldRename: .snake, createToJson: false)
class const NetworkArticleSearchResult({
  required final int categoryId,
  required final String categoryName,
  required final String commentUrl,
  required final String desc,
  required final int id,
  required final List<String> imageUrls,
  required final int isComment,
  required final bool isFold,
  required final bool isRk1,
  required final int like,
  required final int mid,
  required final int pubTime,
  required final int rankIndex,
  required final int rankOffset,
  required final int reply,
  required final int spreadId,
  required final int subType,
  required final int templateId,
  required final HtmlTitle title,
  required final String version,
  required final int view,
}) {
  factory NetworkArticleSearchResult.fromJson(Map<String, dynamic> json) =>
      _$NetworkArticleSearchResultFromJson(json);
}

// @freezed
// abstract class NetworkArticleSearchResult with _$NetworkArticleSearchResult {
//   @JsonSerializable(fieldRename: .snake)
//   const factory NetworkArticleSearchResult({
//     required int categoryId,
//     required String categoryName,
//     required String commentUrl,
//     required String desc,
//     required int id,
//     required List<String> imageUrls,
//     required int isComment,
//     required bool isFold,
//     required bool isRk1,
//     required int like,
//     required int mid,
//     required int pubTime,
//     required int rankIndex,
//     required int rankOffset,
//     required int reply,
//     required int spreadId,
//     required int subType,
//     required int templateId,
//     required HtmlTitle title,
//     required String version,
//     required int view,
//   }) = _NetworkArticleSearchResult;
//
//   factory NetworkArticleSearchResult.fromJson(Map<String, dynamic> json) =>
//       _$NetworkArticleSearchResultFromJson(json);
// }


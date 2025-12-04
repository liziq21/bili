import 'package:freezed_annotation/freezed_annotation.dart';
import '../common/html_title.dart';

part 'network_article_search_result.freezed.dart';
part 'network_article_search_result.g.dart';

@freezed
class NetworkArticleSearchResult with _$NetworkArticleSearchResult {
  @JsonSerializable(fieldRename: .snake)
  const factory NetworkArticleSearchResult({
    required int categoryId,
    required String categoryName,
    required String commentUrl,
    required String desc,
    required int id,
    required List<String> imageUrls,
    required int isComment,
    required bool isFold,
    required bool isRk1,
    required int like,
    required int mid,
    required int pubTime,
    required int rankIndex,
    required int rankOffset,
    required int reply,
    required int spreadId,
    required int subType,
    required int templateId,
    required HtmlTitle title,
    required String version,
    required int view,
  }) = _NetworkArticleSearchResult;

  factory NetworkArticleSearchResult.fromJson(Map<String, dynamic> json) =>
      _$NetworkArticleSearchResultFromJson(json);
}
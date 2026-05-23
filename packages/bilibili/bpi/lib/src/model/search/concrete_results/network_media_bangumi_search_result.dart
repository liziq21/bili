import 'package:freezed_annotation/freezed_annotation.dart';

import '../common/html_title.dart';
import '../common/network_media_score.dart';

part 'network_media_bangumi_search_result.freezed.dart';
part 'network_media_bangumi_search_result.g.dart';

@freezed
abstract class NetworkMediaBangumiSearchResult with _$NetworkMediaBangumiSearchResult {
  @JsonSerializable(fieldRename: .snake)
  const factory NetworkMediaBangumiSearchResult({
    required int mediaId,
    required HtmlTitle title,
    required String orgTitle,
    required int mediaType,
    required String cv,
    required String staff,
    required int seasonId,
    required bool isAvid,
    required String hitEpids,
    required int seasonType,
    required String seasonTypeName,
    required String url,
    required String buttonText,
    required int isSelection,
    required String? cover,
    required String areas,
    required String styles,
    required String gotoUrl,
    required String desc,
    required int pubtime,
    required int mediaMode,
    required NetworkMediaScore mediaScore,
    required String indexShow,
  }) = _NetworkMediaBangumiSearchResult;

  factory NetworkMediaBangumiSearchResult.fromJson(Map<String, dynamic> json) =>
      _$NetworkMediaBangumiSearchResultFromJson(json);
}
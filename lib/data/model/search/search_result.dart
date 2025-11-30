import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../bili/search_result_type.dart';
import '../../../network/model/network_search.dart';

part 'search_result.freezed.dart';

@freezed
class SearchResult with _$SearchResult {
  const factory SearchResult({
    required int page,
    required int pagesize,
    required int numResults,
    required int numPages,
    Map<SearchResultType, String>? pageinfo,
    ) = _SearchResult;
}

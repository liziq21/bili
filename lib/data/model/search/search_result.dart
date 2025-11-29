import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../network/model/network_search.dart';

part 'search_result.freezed.dart';

@freezed
class SearchResult with _$SearchResult {
  const factory SearchResult({
    required result
  }) = _SearchResult;
}

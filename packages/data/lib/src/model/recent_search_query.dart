import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:database/database.dart';

part 'recent_search_query.freezed.dart';

@freezed
abstract class RecentSearchQuery with _$RecentSearchQuery {
  const factory RecentSearchQuery({
    required String query,
    required DateTime queriedDate,
  }) = _RecentSearchQuery;
}

extension RecentSearchQueryEntityX on RecentSearchQueryEntity {
  RecentSearchQuery asExternalModel() {
    return RecentSearchQuery(query: query, queriedDate: queriedDate);
  }
}


import 'package:meta/meta.dart';

import 'model/filter_group.dart';
import 'model/sort_option.dart';

@immutable
class const SearchQuery({
  required final String query,
  final int pageKey = 1,
  final SortOption? sortOption,
  final List<FilterGroup> filters = const [],
}) {
  Map<String, String> get parameters => <String, String>{
    ...?sortOption?.toQueryParams(),
    for (final filter in filters) ...filter.toQueryParams(),
  };

  SearchQuery copyWith({
    String? query,
    int? pageKey,
    SortOption? sortOption,
    List<FilterGroup>? filters,
  }) =>
      SearchQuery(
        query: query ?? this.query,
        pageKey: pageKey ?? this.pageKey,
        sortOption: sortOption ?? this.sortOption,
        filters: filters ?? this.filters,
      );
}

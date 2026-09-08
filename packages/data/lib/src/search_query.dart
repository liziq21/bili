import 'package:meta/meta.dart';

import 'model/filter_group.dart';
import 'model/sort_option.dart';

@immutable
class SearchQuery {
  const SearchQuery({
    required this.query,
    this.pageKey = 1,
    this.sortOption,
    this.filters = const [],
  });

  final String query;
  final int pageKey;
  final SortOption? sortOption;
  final List<FilterGroup> filters;

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

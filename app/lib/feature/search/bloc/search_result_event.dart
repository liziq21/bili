part of 'search_result_bloc.dart';

sealed class const SearchResultEvent() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const FetchNextPage() extends SearchResultEvent;

/// 应用新的筛选条件与排序，并从第一页重新搜索。
final class const ApplySearchOptions({
  required final List<FilterGroup> filters,
  required final SortOption? sortOption,
}) extends SearchResultEvent {
  @override
  List<Object?> get props => [filters, sortOption];
}

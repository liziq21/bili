import 'package:data/data.dart';
import 'package:freezed_annotation/freezed_annotation.dart'; // 建议使用 freezed 保证不可变性

class SearchResultState<T> {
  final String query;
  final SortOption? currentSort;
  final List<FilterGroup> filters;

  final CreatorProfile? creatorProfile;
  final List<VideoInfoBase>? creatorProfileVideos;

  SearchResultState({
    required this.query,
    this.currentSort,
    required this.filters,
    this.creatorProfile,
    this.creatorProfileVideos,
  });

  SearchResultState<T> copyWith({
    String? query,
    SortOption? currentSort,
    List<FilterGroup>? filters,
    CreatorProfile? creatorProfile,
    List<VideoInfoBase>? creatorProfileVideos,
  }) {
    return SearchResultState<T>(
      query: query ?? this.query,
      currentSort: currentSort ?? this.currentSort,
      filters: filters ?? this.filters,
      creatorProfile: creatorProfile ?? this.creatorProfile,
      creatorProfileVideos: creatorProfileVideos ?? this.creatorProfileVideos,
    );
  }
}

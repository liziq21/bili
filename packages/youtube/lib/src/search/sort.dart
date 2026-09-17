import 'package:data/data.dart';

enum YoutubeSearchSort implements SortOption {
  relevance('relevance', 0),
  uploadDate('uploadDate', 1),
  viewCount('viewCount', 2),
  rating('rating', 3);

  const YoutubeSearchSort(this.label, this.valueInt);

  @override
  final String label;

  final int valueInt;

  @override
  String get value => name;

  @override
  Map<String, String> toQueryParams() => {'sort': name};
}

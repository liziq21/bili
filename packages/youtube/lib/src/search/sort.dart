import 'package:data/data.dart';

enum YoutubeSearchSort(@override final String label, final int valueInt)
    implements SortOption {
  relevance('relevance', 0),
  uploadDate('uploadDate', 1),
  viewCount('viewCount', 2),
  rating('rating', 3);

  @override
  String get value => name;

  @override
  Map<String, String> toQueryParams() => {'sort': name};
}

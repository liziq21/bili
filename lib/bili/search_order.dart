
abstract interface class SearchOrder {
  String toJson();
}

abstract class SortOption {
  const SortOption(this.label);
  final String label;
}

enum ArticleSearchOrder implements SearchOrder, SortOption {
  totalrank('totalrank'),
  attention('attention'),
  click('click'),
  dm('dm'),
  pubdate('pubdate'),
  scores('scores'),
  stow('stow');
  
  const ArticleSearchOrder._(this.label);
  
  @override
  String toJson() => name;
  
  @override
  final String label;
}

enum PhotoOrVideoSearchOrder implements SearchOrder, SortOption {
  totalrank('totalrank'),
  click('click'),
  dm('dm'),
  pubdate('pubdate'),
  scores('scores'),
  stow('stow');
  
  const PhotoOrVideoSearchOrder._(this.label);
  
  @override
  String toJson() => toString();
  
  @override
  final String label;
}

enum LiveRoomSearchOrder implements SearchOrder, SortOption {
  online('online'), liveTime('liveTime');
  
  const LiveRoomSearchOrder._(this.label);
  
  @override
  String toString() => this == liveTime ? 'live_time' : super.toString();
  
  @override
  String toJson() => toString();

  @override
  final String label;

}

enum UserSearchOrder implements SearchOrder {
  defaultOrder, fons, level;
  
  String toString() => this == defaultOrder ? '0' : super.toString();

  @override
  String toJson() => toString();

}

enum OrderSort {
  descending, ascending;
  
  @override
  String toString() => '$index';
  
  String toJson() => toString();
}

enum UserSearchSort implements SortOption {
  defaultSort('defaultSort', null, null),
  fonsDescending('fonsDescending', .fons, .descending),
  fonsAscending('fonsAscending', .fons, .ascending),
  levelDescending('levelDescending', .level, .descending),
  levelAscending('levelAscending', .level, .ascending);
  
  const UserSearchSort._(
    this.label,
    this.order, [
    this.orderSort,
  ]);
  

  final UserSearchOrder? order;
  final OrderSort? orderSort;

  @override
  final String label;
}

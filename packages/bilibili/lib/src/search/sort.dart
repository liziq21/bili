
enum ArticleSearchSort implements SortOption {
  totalrank('totalrank'),
  attention('attention'),
  click('click'),
  dm('dm'),
  pubdate('pubdate'),
  scores('scores'),
  stow('stow');
  
  const ArticleSearchSort(super.label);
  
  @override
  String get value => name;
  
  @override
  Map<String, String> toQueryParams() => { 'order': name };
}

enum PhotoOrVideoSearchSort implements SortOption {
  totalrank('totalrank'),
  click('click'),
  dm('dm'),
  pubdate('pubdate'),
  scores('scores'),
  stow('stow');
  
  const PhotoOrVideoSearchSort(super.label);
  
  @override
  String get value => name;
  
  @override
  Map<String, String> toQueryParams() => { 'order': name };
}

enum LiveRoomSearchSort implements SortOption {
  online('online'), liveTime('liveTime');
  
  const LiveRoomSearchSort(super.label);
  
  @override
  String get value => name;
  
  @override
  Map<String, String> toQueryParams() => { 
    'order': switch(this) {
      liveTime => 'live_time',
      _ => name,
    },
  };
}

enum UserSearchSort implements SortOption {
  defaultSort('defaultSort', null, null),
  fonsDescending('fonsDescending', .fons, .descending),
  fonsAscending('fonsAscending', .fons, .ascending),
  levelDescending('levelDescending', .level, .descending),
  levelAscending('levelAscending', .level, .ascending);
  
  const UserSearchSort(
    super.label,
    this.order,
    this.orderSort,
  );
  
  final UserSearchSort? order;
  final OrderSort? orderSort;
  
  @override
  String get value => name;
  
  @override
  Map<String, String> toQueryParams() => {
    ...?order?.toQueryParams(),
    ...?orderSort?.toQueryParams(),
  };
}

enum UserSearchSort {
  defaultOrder, fons, level;
  
  Map<String, String> toQueryParams() => {
    'order': switch(this) {
      defaultOrder => '0',
      _ => name,
    },
  };
}

enum OrderSort {
  descending, ascending;
  
  Map<String, String> toQueryParams() => { 'order_sort': '$index' };
}
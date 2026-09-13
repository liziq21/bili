import 'package:data/data.dart';

enum ArticleSearchSort implements SortOption {
  totalrank('totalrank'),
  attention('attention'),
  click('click'),
  dm('dm'),
  pubdate('pubdate'),
  scores('scores'),
  stow('stow');

  const ArticleSearchSort(this.label);

  @override
  final String label;

  @override
  String get value => name;

  @override
  Map<String, String> toQueryParams() => {'order': name};
}

enum PhotoOrVideoSearchSort implements SortOption {
  totalrank('totalrank'),
  click('click'),
  dm('dm'),
  pubdate('pubdate'),
  scores('scores'),
  stow('stow');

  const PhotoOrVideoSearchSort(this.label);

  @override
  final String label;

  @override
  String get value => name;

  @override
  Map<String, String> toQueryParams() => {'order': name};
}

enum LiveRoomSearchSort implements SortOption {
  online('online'),
  liveTime('liveTime');

  const LiveRoomSearchSort(this.label);

  @override
  final String label;

  @override
  String get value => name;

  @override
  Map<String, String> toQueryParams() => {
    'order': switch (this) {
      liveTime => 'live_time',
      _ => name,
    },
  };
}

enum UserSearchSort implements SortOption {
  defaultSort('defaultSort', null, null),
  fonsDescending('fonsDescending', UserSearchOrder.fons, OrderSort.descending),
  fonsAscending('fonsAscending', UserSearchOrder.fons, OrderSort.ascending),
  levelDescending(
    'levelDescending',
    UserSearchOrder.level,
    OrderSort.descending,
  ),
  levelAscending('levelAscending', UserSearchOrder.level, OrderSort.ascending);

  const UserSearchSort(this.label, this.order, this.orderSort);

  @override
  final String label;
  final UserSearchOrder? order;
  final OrderSort? orderSort;

  @override
  String get value => name;

  @override
  Map<String, String> toQueryParams() => {
    ...?order?.toQueryParams(),
    ...?orderSort?.toQueryParams(),
  };
}

enum UserSearchOrder {
  defaultOrder,
  fons,
  level;

  Map<String, String> toQueryParams() => {
    'order': switch (this) {
      defaultOrder => '0',
      _ => name,
    },
  };
}

enum OrderSort {
  descending,
  ascending;

  Map<String, String> toQueryParams() => {'order_sort': '$index'};
}

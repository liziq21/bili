import 'package:data/data.dart';

enum ArticleSearchSort(@override final String label) implements SortOption {
  totalrank('totalrank'),
  attention('attention'),
  click('click'),
  dm('dm'),
  pubdate('pubdate'),
  scores('scores'),
  stow('stow');

  @override
  String get value => name;

  @override
  Map<String, String> toQueryParams() => {'order': name};
}

enum PhotoOrVideoSearchSort(@override final String label)
    implements SortOption {
  totalrank('totalrank'),
  click('click'),
  dm('dm'),
  pubdate('pubdate'),
  scores('scores'),
  stow('stow');

  @override
  String get value => name;

  @override
  Map<String, String> toQueryParams() => {'order': name};
}

enum LiveRoomSearchSort(@override final String label) implements SortOption {
  online('online'),
  liveTime('liveTime');

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

enum UserSearchSort(
  @override final String label,
  final UserSearchOrder? order,
  final OrderSort? orderSort,
) implements SortOption {
  defaultSort('defaultSort', null, null),
  fonsDescending('fonsDescending', UserSearchOrder.fons, OrderSort.descending),
  fonsAscending('fonsAscending', UserSearchOrder.fons, OrderSort.ascending),
  levelDescending(
    'levelDescending',
    UserSearchOrder.level,
    OrderSort.descending,
  ),
  levelAscending('levelAscending', UserSearchOrder.level, OrderSort.ascending);

  @override
  String get value => name;

  @override
  Map<String, String> toQueryParams() => {
    ...?order?.toQueryParams(),
    ...?orderSort?.toQueryParams(),
  };
}

enum UserSearchOrder() {
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

enum OrderSort() {
  descending,
  ascending;

  Map<String, String> toQueryParams() => {'order_sort': '$index'};
}

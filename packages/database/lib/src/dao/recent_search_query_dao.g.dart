// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_search_query_dao.dart';

// ignore_for_file: type=lint
mixin _$RecentSearchQueryDaoMixin on DatabaseAccessor<BiliDatabase> {
  $RecentSearchQueryTable get recentSearchQuery =>
      attachedDatabase.recentSearchQuery;
  RecentSearchQueryDaoManager get managers => RecentSearchQueryDaoManager(this);
}

class RecentSearchQueryDaoManager {
  final _$RecentSearchQueryDaoMixin _db;
  RecentSearchQueryDaoManager(this._db);
  $$RecentSearchQueryTableTableManager get recentSearchQuery =>
      $$RecentSearchQueryTableTableManager(
        _db.attachedDatabase,
        _db.recentSearchQuery,
      );
}

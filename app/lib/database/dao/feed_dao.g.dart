// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_dao.dart';

// ignore_for_file: type=lint
mixin _$FeedDaoMixin on DatabaseAccessor<AppDatabase> {
  $FeedEntryTable get feedEntry => attachedDatabase.feedEntry;
  FeedDaoManager get managers => FeedDaoManager(this);
}

class FeedDaoManager {
  final _$FeedDaoMixin _db;
  FeedDaoManager(this._db);
  $$FeedEntryTableTableManager get feedEntry =>
      $$FeedEntryTableTableManager(_db.attachedDatabase, _db.feedEntry);
}

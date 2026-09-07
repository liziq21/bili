// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_history_dao.dart';

// ignore_for_file: type=lint
mixin _$MediaHistoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $MediaTable get media => attachedDatabase.media;
  $MediaHistoryTable get mediaHistory => attachedDatabase.mediaHistory;
  MediaHistoryDaoManager get managers => MediaHistoryDaoManager(this);
}

class MediaHistoryDaoManager {
  final _$MediaHistoryDaoMixin _db;
  MediaHistoryDaoManager(this._db);
  $$MediaTableTableManager get media =>
      $$MediaTableTableManager(_db.attachedDatabase, _db.media);
  $$MediaHistoryTableTableManager get mediaHistory =>
      $$MediaHistoryTableTableManager(_db.attachedDatabase, _db.mediaHistory);
}

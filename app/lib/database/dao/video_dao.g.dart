// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_dao.dart';

// ignore_for_file: type=lint
mixin _$VideoDaoMixin on DatabaseAccessor<AppDatabase> {
  $MediaTable get media => attachedDatabase.media;
  $VideoTable get video => attachedDatabase.video;
  VideoDaoManager get managers => VideoDaoManager(this);
}

class VideoDaoManager {
  final _$VideoDaoMixin _db;
  VideoDaoManager(this._db);
  $$MediaTableTableManager get media =>
      $$MediaTableTableManager(_db.attachedDatabase, _db.media);
  $$VideoTableTableManager get video =>
      $$VideoTableTableManager(_db.attachedDatabase, _db.video);
}

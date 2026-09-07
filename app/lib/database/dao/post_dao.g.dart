// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_dao.dart';

// ignore_for_file: type=lint
mixin _$PostDaoMixin on DatabaseAccessor<AppDatabase> {
  $MediaTable get media => attachedDatabase.media;
  $PostTable get post => attachedDatabase.post;
  PostDaoManager get managers => PostDaoManager(this);
}

class PostDaoManager {
  final _$PostDaoMixin _db;
  PostDaoManager(this._db);
  $$MediaTableTableManager get media =>
      $$MediaTableTableManager(_db.attachedDatabase, _db.media);
  $$PostTableTableManager get post =>
      $$PostTableTableManager(_db.attachedDatabase, _db.post);
}

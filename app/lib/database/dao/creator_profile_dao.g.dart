// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creator_profile_dao.dart';

// ignore_for_file: type=lint
mixin _$CreatorProfileDaoMixin on DatabaseAccessor<AppDatabase> {
  $CreatorProfileTable get creatorProfile => attachedDatabase.creatorProfile;
  CreatorProfileDaoManager get managers => CreatorProfileDaoManager(this);
}

class CreatorProfileDaoManager {
  final _$CreatorProfileDaoMixin _db;
  CreatorProfileDaoManager(this._db);
  $$CreatorProfileTableTableManager get creatorProfile =>
      $$CreatorProfileTableTableManager(
        _db.attachedDatabase,
        _db.creatorProfile,
      );
}

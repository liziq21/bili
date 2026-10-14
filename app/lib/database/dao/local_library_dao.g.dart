// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_library_dao.dart';

// ignore_for_file: type=lint
mixin _$LocalLibraryDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalBookmarkTable get localBookmark => attachedDatabase.localBookmark;
  $LocalPlaylistTable get localPlaylist => attachedDatabase.localPlaylist;
  $LocalPlaylistItemTable get localPlaylistItem =>
      attachedDatabase.localPlaylistItem;
  $LocalSubscriptionTable get localSubscription =>
      attachedDatabase.localSubscription;
  LocalLibraryDaoManager get managers => LocalLibraryDaoManager(this);
}

class LocalLibraryDaoManager {
  final _$LocalLibraryDaoMixin _db;
  LocalLibraryDaoManager(this._db);
  $$LocalBookmarkTableTableManager get localBookmark =>
      $$LocalBookmarkTableTableManager(_db.attachedDatabase, _db.localBookmark);
  $$LocalPlaylistTableTableManager get localPlaylist =>
      $$LocalPlaylistTableTableManager(_db.attachedDatabase, _db.localPlaylist);
  $$LocalPlaylistItemTableTableManager get localPlaylistItem =>
      $$LocalPlaylistItemTableTableManager(
        _db.attachedDatabase,
        _db.localPlaylistItem,
      );
  $$LocalSubscriptionTableTableManager get localSubscription =>
      $$LocalSubscriptionTableTableManager(
        _db.attachedDatabase,
        _db.localSubscription,
      );
}

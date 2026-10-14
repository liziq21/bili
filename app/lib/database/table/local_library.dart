import 'package:drift/drift.dart';

// Keep local-library snapshots independent of the evictable media/creator
// cache: clearing history or cached metadata must not remove saved items.

/// A locally saved video bookmark.
@DataClassName('LocalBookmarkEntity')
class LocalBookmark() extends Table {
  IntColumn get internalId => integer().autoIncrement()();
  TextColumn get sourceId => text()();
  TextColumn get originalId => text()();
  TextColumn get title => text()();
  TextColumn get url => text()();
  TextColumn get thumbnailUrl => text().nullable()();
  TextColumn get creatorProfileId => text().nullable()();
  TextColumn get creatorProfileName => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'local_bookmark';

  @override
  List<Set<Column>> get uniqueKeys => [
    {sourceId, originalId},
  ];
}

/// A source-scoped local playlist.
@DataClassName('LocalPlaylistEntity')
class LocalPlaylist() extends Table {
  IntColumn get internalId => integer().autoIncrement()();
  TextColumn get sourceId => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'local_playlist';

  @override
  List<Set<Column>> get uniqueKeys => [
    {sourceId, name},
  ];
}

/// An ordered playlist entry. There is intentionally no uniqueness constraint:
/// users may add the same video more than once.
@DataClassName('LocalPlaylistItemEntity')
class LocalPlaylistItem() extends Table {
  IntColumn get internalId => integer().autoIncrement()();
  IntColumn get playlistId => integer().references(
    LocalPlaylist,
    #internalId,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get sourceId => text()();
  TextColumn get originalId => text()();
  TextColumn get title => text()();
  TextColumn get url => text()();
  TextColumn get thumbnailUrl => text().nullable()();
  IntColumn get position => integer()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'local_playlist_item';
}

/// A source-scoped local creator subscription.
@DataClassName('LocalSubscriptionEntity')
class LocalSubscription() extends Table {
  IntColumn get internalId => integer().autoIncrement()();
  TextColumn get sourceId => text()();
  TextColumn get originalId => text()();
  TextColumn get name => text()();
  TextColumn get thumbnailUrl => text().nullable()();
  TextColumn get groupName => text().withDefault(const Constant(''))();
  DateTimeColumn get subscribedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'local_subscription';

  @override
  List<Set<Column>> get uniqueKeys => [
    {sourceId, originalId},
  ];
}

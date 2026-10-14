import 'package:drift/drift.dart';

import '../app_database.dart';
import '../table/local_library.dart';

part 'local_library_dao.g.dart';

@DriftAccessor(
  tables: [LocalBookmark, LocalPlaylist, LocalPlaylistItem, LocalSubscription],
)
class LocalLibraryDao(super.db)
    extends DatabaseAccessor<AppDatabase>
    with _$LocalLibraryDaoMixin {
  Future<bool> isBookmarked(String sourceId, String originalId) async {
    _requireMediaIdentity(sourceId, originalId);
    final row =
        await (select(localBookmark)..where(
              (bookmark) =>
                  bookmark.sourceId.equals(sourceId) &
                  bookmark.originalId.equals(originalId),
            ))
            .getSingleOrNull();
    return row != null;
  }

  Future<void> saveBookmark(LocalBookmarkCompanion bookmark) async {
    _requireCompanionIdentity(
      sourceId: bookmark.sourceId,
      originalId: bookmark.originalId,
    );
    await into(localBookmark).insertReturning(
      bookmark.copyWith(internalId: const Value.absent()),
      onConflict: DoUpdate(
        (_) => LocalBookmarkCompanion(
          title: bookmark.title,
          url: bookmark.url,
          thumbnailUrl: bookmark.thumbnailUrl,
          creatorProfileId: bookmark.creatorProfileId,
          creatorProfileName: bookmark.creatorProfileName,
        ),
        target: [localBookmark.sourceId, localBookmark.originalId],
      ),
    );
  }

  Future<void> removeBookmark(String sourceId, String originalId) async {
    _requireMediaIdentity(sourceId, originalId);
    await (delete(localBookmark)..where(
          (bookmark) =>
              bookmark.sourceId.equals(sourceId) &
              bookmark.originalId.equals(originalId),
        ))
        .go();
  }

  Future<List<LocalBookmarkEntity>> getBookmarks() => _bookmarks().get();

  Stream<List<LocalBookmarkEntity>> watchBookmarks() => _bookmarks().watch();

  Future<bool> isSubscribed(String sourceId, String originalId) async {
    _requireMediaIdentity(sourceId, originalId);
    final row =
        await (select(localSubscription)..where(
              (subscription) =>
                  subscription.sourceId.equals(sourceId) &
                  subscription.originalId.equals(originalId),
            ))
            .getSingleOrNull();
    return row != null;
  }

  Future<void> saveSubscription(LocalSubscriptionCompanion subscription) async {
    _requireCompanionIdentity(
      sourceId: subscription.sourceId,
      originalId: subscription.originalId,
    );
    _requireNonBlank(
      _requiredCompanionValue(subscription.name, 'name'),
      'name',
    );
    await into(localSubscription).insertReturning(
      subscription.copyWith(internalId: const Value.absent()),
      onConflict: DoUpdate(
        // Group membership is user-managed metadata. A creator refresh
        // must not clear it when updating the cached creator snapshot.
        (_) => LocalSubscriptionCompanion(
          name: subscription.name,
          thumbnailUrl: subscription.thumbnailUrl,
        ),
        target: [localSubscription.sourceId, localSubscription.originalId],
      ),
    );
  }

  Future<void> removeSubscription(String sourceId, String originalId) async {
    _requireMediaIdentity(sourceId, originalId);
    await (delete(localSubscription)..where(
          (subscription) =>
              subscription.sourceId.equals(sourceId) &
              subscription.originalId.equals(originalId),
        ))
        .go();
  }

  Future<List<LocalSubscriptionEntity>> getSubscriptions() =>
      _subscriptions().get();

  Stream<List<LocalSubscriptionEntity>> watchSubscriptions() =>
      _subscriptions().watch();

  Future<void> setSubscriptionGroup(
    String sourceId,
    String originalId,
    String groupName,
  ) async {
    _requireMediaIdentity(sourceId, originalId);
    await (update(localSubscription)..where(
          (subscription) =>
              subscription.sourceId.equals(sourceId) &
              subscription.originalId.equals(originalId),
        ))
        .write(LocalSubscriptionCompanion(groupName: Value(groupName)));
  }

  Future<int> createPlaylist(String sourceId, String name) async {
    _requireNonBlank(sourceId, 'sourceId');
    _requireNonBlank(name, 'name');
    final inserted = await into(localPlaylist).insertReturning(
      LocalPlaylistCompanion.insert(sourceId: sourceId, name: name),
    );
    return inserted.internalId;
  }

  Future<void> deletePlaylist(int playlistId) async {
    await (delete(
      localPlaylist,
    )..where((playlist) => playlist.internalId.equals(playlistId))).go();
  }

  Future<List<LocalPlaylistEntity>> getPlaylists() => _playlists().get();

  Stream<List<LocalPlaylistEntity>> watchPlaylists() => _playlists().watch();

  Future<List<LocalPlaylistItemEntity>> getPlaylistItems(int playlistId) =>
      _playlistItems(playlistId).get();

  Stream<List<LocalPlaylistItemEntity>> watchPlaylistItems(int playlistId) =>
      _playlistItems(playlistId).watch();

  Future<void> addPlaylistItem({
    required int playlistId,
    required LocalPlaylistItemCompanion item,
  }) => addPlaylistItems(playlistId: playlistId, items: [item]);

  Future<void> addPlaylistItems({
    required int playlistId,
    required List<LocalPlaylistItemCompanion> items,
  }) async {
    await transaction(() async {
      final playlist = await _requirePlaylist(playlistId);
      if (items.isEmpty) return;
      var nextPosition = (await getPlaylistItems(playlistId)).length;

      for (final item in items) {
        final sourceId = _requiredCompanionValue(item.sourceId, 'sourceId');
        final originalId = _requiredCompanionValue(
          item.originalId,
          'originalId',
        );
        _requireNonBlank(sourceId, 'sourceId');
        _requireNonBlank(originalId, 'originalId');
        if (sourceId != playlist.sourceId) {
          throw ArgumentError.value(
            sourceId,
            'sourceId',
            'must match the playlist sourceId',
          );
        }

        await into(localPlaylistItem).insert(
          item.copyWith(
            internalId: const Value.absent(),
            playlistId: Value(playlistId),
            position: Value(nextPosition++),
          ),
        );
      }
      await _touchPlaylist(playlistId);
    });
  }

  Future<void> removePlaylistItem(int itemId) async {
    await transaction(() async {
      final item = await (select(
        localPlaylistItem,
      )..where((entry) => entry.internalId.equals(itemId))).getSingleOrNull();
      if (item == null) return;
      await (delete(
        localPlaylistItem,
      )..where((entry) => entry.internalId.equals(itemId))).go();
      await _normalizePlaylistPositions(item.playlistId);
      await _touchPlaylist(item.playlistId);
    });
  }

  Future<void> movePlaylistItem({
    required int playlistId,
    required int fromIndex,
    required int toIndex,
  }) async {
    await transaction(() async {
      final items = await getPlaylistItems(playlistId);
      if (fromIndex < 0 || fromIndex >= items.length) return;
      // toIndex is the final zero-based index (not a ReorderableListView gap).
      final boundedTarget = toIndex.clamp(0, items.length - 1);
      if (fromIndex == boundedTarget) return;
      final reordered = List<LocalPlaylistItemEntity>.of(items);
      final moved = reordered.removeAt(fromIndex);
      reordered.insert(boundedTarget, moved);
      await _writePositions(reordered);
      await _touchPlaylist(playlistId);
    });
  }

  Future<void> _normalizePlaylistPositions(int playlistId) async {
    await _writePositions(await getPlaylistItems(playlistId));
  }

  Future<void> _writePositions(List<LocalPlaylistItemEntity> items) async {
    for (var index = 0; index < items.length; index++) {
      await (update(localPlaylistItem)
            ..where((item) => item.internalId.equals(items[index].internalId)))
          .write(LocalPlaylistItemCompanion(position: Value(index)));
    }
  }

  Future<void> _touchPlaylist(int playlistId) async {
    await (update(localPlaylist)
          ..where((playlist) => playlist.internalId.equals(playlistId)))
        .write(LocalPlaylistCompanion(updatedAt: Value(DateTime.now())));
  }

  Selectable<LocalBookmarkEntity> _bookmarks() =>
      select(localBookmark)..orderBy([
        (bookmark) => OrderingTerm.desc(bookmark.createdAt),
        (bookmark) => OrderingTerm.desc(bookmark.internalId),
      ]);

  Selectable<LocalSubscriptionEntity> _subscriptions() =>
      select(localSubscription)..orderBy([
        (subscription) => OrderingTerm.asc(subscription.name),
        (subscription) => OrderingTerm.asc(subscription.internalId),
      ]);

  Selectable<LocalPlaylistEntity> _playlists() =>
      select(localPlaylist)..orderBy([
        (playlist) => OrderingTerm.desc(playlist.updatedAt),
        (playlist) => OrderingTerm.desc(playlist.internalId),
      ]);

  Selectable<LocalPlaylistItemEntity> _playlistItems(int playlistId) =>
      (select(localPlaylistItem)
        ..where((item) => item.playlistId.equals(playlistId))
        ..orderBy([
          (item) => OrderingTerm.asc(item.position),
          (item) => OrderingTerm.asc(item.internalId),
        ]));

  Future<LocalPlaylistEntity> _requirePlaylist(int playlistId) async {
    final playlist = await (select(
      localPlaylist,
    )..where((entry) => entry.internalId.equals(playlistId))).getSingleOrNull();
    if (playlist == null) {
      throw StateError('Playlist $playlistId does not exist');
    }
    return playlist;
  }

  String _requiredCompanionValue(Value<String> value, String name) {
    if (!value.present) {
      throw ArgumentError('Missing required $name');
    }
    return value.value;
  }

  void _requireCompanionIdentity({
    required Value<String> sourceId,
    required Value<String> originalId,
  }) {
    _requireMediaIdentity(
      _requiredCompanionValue(sourceId, 'sourceId'),
      _requiredCompanionValue(originalId, 'originalId'),
    );
  }

  void _requireMediaIdentity(String sourceId, String originalId) {
    _requireNonBlank(sourceId, 'sourceId');
    _requireNonBlank(originalId, 'originalId');
  }

  void _requireNonBlank(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'must not be blank');
    }
  }
}

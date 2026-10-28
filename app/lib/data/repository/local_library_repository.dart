import 'package:drift/drift.dart';
import 'package:data/data.dart';

import '../../database/app_database.dart';
import '../../database/dao/local_library_dao.dart';
import '../../database/local_media_key.dart';

/// Coordinates local-only bookmarks, playlists, and subscriptions.
///
/// The repository receives the source identity from the route scope. It never
/// imports a concrete service package and therefore keeps local
/// personalization source-neutral.
class LocalLibraryRepository({required final LocalLibraryDao dao}) {
  Future<bool> isBookmarked(String sourceId, String originalId) async {
    final key = _mediaKey(sourceId, originalId);
    return dao.isBookmarked(key.sourceId, key.originalId);
  }

  Future<void> setBookmark({
    required String sourceId,
    required VideoModel video,
    required bool bookmarked,
  }) async {
    final key = _mediaKey(sourceId, video.id);
    if (bookmarked) {
      await dao.saveBookmark(
        LocalBookmarkCompanion.insert(
          sourceId: key.sourceId,
          originalId: key.originalId,
          title: video.title,
          url: video.url,
          thumbnailUrl: Value(video.thumbnailUrl),
          creatorProfileId: Value(video.creatorProfileId),
          creatorProfileName: Value(video.creatorProfileName),
        ),
      );
    } else {
      await dao.removeBookmark(key.sourceId, key.originalId);
    }
  }

  Future<List<LocalBookmarkEntity>> getBookmarks() => dao.getBookmarks();

  Future<bool> isSubscribed(String sourceId, String originalId) async {
    final key = _mediaKey(sourceId, originalId);
    return dao.isSubscribed(key.sourceId, key.originalId);
  }

  Future<void> setSubscription({
    required String sourceId,
    required CreatorProfile creator,
    required bool subscribed,
  }) async {
    final key = _mediaKey(sourceId, creator.id);
    if (subscribed) {
      await dao.saveSubscription(
        LocalSubscriptionCompanion.insert(
          sourceId: key.sourceId,
          originalId: key.originalId,
          name: creator.name,
          thumbnailUrl: Value(creator.thumbnailUrl),
        ),
      );
    } else {
      await dao.removeSubscription(key.sourceId, key.originalId);
    }
  }

  Future<List<LocalSubscriptionEntity>> getSubscriptions() =>
      dao.getSubscriptions();

  Stream<List<LocalBookmarkEntity>> watchBookmarks() => dao.watchBookmarks();

  Stream<List<LocalSubscriptionEntity>> watchSubscriptions() =>
      dao.watchSubscriptions();

  Future<void> setSubscriptionGroup(
    String sourceId,
    String originalId,
    String groupName,
  ) => dao.setSubscriptionGroup(sourceId, originalId, groupName);

  Future<int> createPlaylist(String sourceId, String name) =>
      dao.createPlaylist(sourceId, name);

  Future<void> deletePlaylist(int playlistId) => dao.deletePlaylist(playlistId);

  Future<void> renamePlaylist(int playlistId, String name) =>
      dao.renamePlaylist(playlistId, name);

  Future<List<LocalPlaylistEntity>> getPlaylists() => dao.getPlaylists();

  Stream<List<LocalPlaylistEntity>> watchPlaylists() => dao.watchPlaylists();

  Future<List<LocalPlaylistItemEntity>> getPlaylistItems(
    int playlistId, {
    String query = '',
  }) => dao.getPlaylistItems(playlistId, query: query);

  Stream<List<LocalPlaylistItemEntity>> watchPlaylistItems(
    int playlistId, {
    String query = '',
  }) => dao.watchPlaylistItems(playlistId, query: query);

  Future<void> addToPlaylist({
    required int playlistId,
    required String sourceId,
    required VideoModel video,
  }) => addVideosToPlaylist(
    playlistId: playlistId,
    sourceId: sourceId,
    videos: [video],
  );

  Future<void> addVideosToPlaylist({
    required int playlistId,
    required String sourceId,
    required List<VideoModel> videos,
  }) async {
    _requireNonBlank(sourceId, 'sourceId');
    return dao.addPlaylistItems(
      playlistId: playlistId,
      items: [
        for (final video in videos) _playlistItem(playlistId, sourceId, video),
      ],
    );
  }

  Future<void> removePlaylistItem(int itemId) => dao.removePlaylistItem(itemId);

  Future<void> deletePlaylistItems({
    required int playlistId,
    required List<int> itemIds,
  }) => dao.deletePlaylistItems(playlistId: playlistId, itemIds: itemIds);

  Future<void> movePlaylistItem({
    required int playlistId,
    required int fromIndex,
    required int toIndex,
  }) => dao.movePlaylistItem(
    playlistId: playlistId,
    fromIndex: fromIndex,
    toIndex: toIndex,
  );

  LocalMediaKey _mediaKey(String sourceId, String originalId) {
    _requireNonBlank(sourceId, 'sourceId');
    _requireNonBlank(originalId, 'originalId');
    return LocalMediaKey(sourceId, originalId);
  }

  void _requireNonBlank(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'must not be blank');
    }
  }

  LocalPlaylistItemCompanion _playlistItem(
    int playlistId,
    String sourceId,
    VideoModel video,
  ) {
    final key = _mediaKey(sourceId, video.id);
    return LocalPlaylistItemCompanion.insert(
      playlistId: playlistId,
      sourceId: key.sourceId,
      originalId: key.originalId,
      title: video.title,
      url: video.url,
      thumbnailUrl: Value(video.thumbnailUrl),
      position: 0,
    );
  }
}

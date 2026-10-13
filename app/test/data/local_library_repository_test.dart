import 'package:app/database/app_database.dart';
import 'package:app/data/repository/local_library_repository.dart';
import 'package:data/data.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late LocalLibraryRepository repository;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repository = LocalLibraryRepository(dao: db.localLibraryDao);
  });

  tearDown(() => db.close());

  test(
    'keeps bookmark and subscription identities isolated by source',
    () async {
      final video = _video('same-id');
      final creator = _creator('same-id');

      await repository.setBookmark(
        sourceId: 'source-a',
        video: video,
        bookmarked: true,
      );
      await repository.setBookmark(
        sourceId: 'source-b',
        video: video,
        bookmarked: true,
      );
      await repository.setSubscription(
        sourceId: 'source-a',
        creator: creator,
        subscribed: true,
      );
      await repository.setSubscription(
        sourceId: 'source-b',
        creator: creator,
        subscribed: true,
      );

      expect(await repository.isBookmarked('source-a', 'same-id'), isTrue);
      expect(await repository.isBookmarked('source-b', 'same-id'), isTrue);
      expect(await repository.isSubscribed('source-a', 'same-id'), isTrue);
      expect(await repository.isSubscribed('source-b', 'same-id'), isTrue);

      await repository.setBookmark(
        sourceId: 'source-a',
        video: video,
        bookmarked: false,
      );
      await repository.setSubscription(
        sourceId: 'source-a',
        creator: creator,
        subscribed: false,
      );

      expect(await repository.isBookmarked('source-a', 'same-id'), isFalse);
      expect(await repository.isBookmarked('source-b', 'same-id'), isTrue);
      expect(await repository.isSubscribed('source-a', 'same-id'), isFalse);
      expect(await repository.isSubscribed('source-b', 'same-id'), isTrue);

      await repository.setBookmark(
        sourceId: 'source-a',
        video: video,
        bookmarked: false,
      );
      await repository.setSubscription(
        sourceId: 'source-a',
        creator: creator,
        subscribed: false,
      );
    },
  );

  test(
    'supports ordered duplicates, source rejection, and atomic batches',
    () async {
      final playlistId = await repository.createPlaylist('source-a', 'Queue');
      await repository.addVideosToPlaylist(
        playlistId: playlistId,
        sourceId: 'source-a',
        videos: [_video('video-1'), _video('video-1'), _video('video-2')],
      );

      final initialItems = await repository.getPlaylistItems(playlistId);
      expect(initialItems.map((item) => item.originalId), [
        'video-1',
        'video-1',
        'video-2',
      ]);
      expect(initialItems.map((item) => item.internalId).toSet(), hasLength(3));
      expect(initialItems.map((item) => item.position), [0, 1, 2]);

      await repository.movePlaylistItem(
        playlistId: playlistId,
        fromIndex: 0,
        toIndex: 2,
      );
      final movedItems = await repository.getPlaylistItems(playlistId);
      expect(movedItems.map((item) => item.originalId), [
        'video-1',
        'video-2',
        'video-1',
      ]);

      await repository.removePlaylistItem(movedItems[1].internalId);
      expect(
        (await repository.getPlaylistItems(playlistId))
            .map((item) => item.position),
        [0, 1],
      );

      await expectLater(
        repository.addToPlaylist(
          playlistId: playlistId,
          sourceId: 'source-b',
          video: _video('other-source-video'),
        ),
        throwsArgumentError,
      );

      final secondPlaylistId = await repository.createPlaylist(
        'source-a',
        'Atomic queue',
      );
      await expectLater(
        repository.addVideosToPlaylist(
          playlistId: secondPlaylistId,
          sourceId: 'source-a',
          videos: [_video('valid'), _video('')],
        ),
        throwsArgumentError,
      );
      expect(await repository.getPlaylistItems(secondPlaylistId), isEmpty);
    },
  );

  test(
    'persists subscription groups and exposes reactive library streams',
    () async {
      final bookmarkChanges = expectLater(
        repository.watchBookmarks(),
        emitsInOrder([isEmpty, hasLength(1), isEmpty]),
      ).timeout(const Duration(seconds: 10));
      final subscriptionChanges = expectLater(
        repository.watchSubscriptions(),
        emitsInOrder([isEmpty, hasLength(1)]),
      ).timeout(const Duration(seconds: 10));
      await Future<void>.delayed(Duration.zero);

      await repository.setBookmark(
        sourceId: 'source-a',
        video: _video('video-1'),
        bookmarked: true,
      );
      await repository.setBookmark(
        sourceId: 'source-a',
        video: _video('video-1'),
        bookmarked: false,
      );
      await repository.setSubscription(
        sourceId: 'source-a',
        creator: _creator('creator-1'),
        subscribed: true,
      );
      await repository.setSubscriptionGroup('source-a', 'creator-1', 'Editors');
      expect((await repository.getSubscriptions()).single.groupName, 'Editors');
      await repository.setSubscription(
        sourceId: 'source-a',
        creator: _creator('creator-1', name: 'Renamed'),
        subscribed: true,
      );
      expect((await repository.getSubscriptions()).single.groupName, 'Editors');

      await Future.wait([bookmarkChanges, subscriptionChanges]);

      final playlistChanges = expectLater(
        repository.watchPlaylists(),
        emitsInOrder([isEmpty, hasLength(1)]),
      ).timeout(const Duration(seconds: 10));
      await Future<void>.delayed(Duration.zero);
      final playlistId = await repository.createPlaylist(
        'source-a',
        'Reactive',
      );
      final itemChanges = expectLater(
        repository.watchPlaylistItems(playlistId),
        emitsInOrder([isEmpty, hasLength(1), isEmpty]),
      ).timeout(const Duration(seconds: 10));
      await Future<void>.delayed(Duration.zero);
      await repository.addToPlaylist(
        playlistId: playlistId,
        sourceId: 'source-a',
        video: _video('video-2'),
      );
      final item = (await repository.getPlaylistItems(playlistId)).single;
      await repository.removePlaylistItem(item.internalId);
      await Future.wait([playlistChanges, itemChanges]);
      // StreamMatcher cancels its StreamQueue asynchronously after matching.
      // Let that cancellation reach Drift before the database is torn down.
      await Future<void>.delayed(Duration.zero);
      await repository.deletePlaylist(playlistId);
      await Future<void>.delayed(Duration.zero);
    },
  );

  test(
    'reopens the same native in-memory sqlite database with saved data',
    () async {
      final rawDatabase = sqlite.sqlite3.openInMemory();
      final first = AppDatabase(
        NativeDatabase.opened(rawDatabase, closeUnderlyingOnClose: false),
      );
      final firstRepository = LocalLibraryRepository(
        dao: first.localLibraryDao,
      );
      final playlistId = await firstRepository.createPlaylist(
        'source-a',
        'Saved',
      );
      await firstRepository.setBookmark(
        sourceId: 'source-a',
        video: _video('persisted'),
        bookmarked: true,
      );
      await first.close();

      final reopened = AppDatabase(NativeDatabase.opened(rawDatabase));
      addTearDown(reopened.close);
      final reopenedRepository = LocalLibraryRepository(
        dao: reopened.localLibraryDao,
      );

      expect(
        (await reopenedRepository.getPlaylists()).single.internalId,
        playlistId,
      );
      expect(
        await reopenedRepository.isBookmarked('source-a', 'persisted'),
        isTrue,
      );
    },
  );
}

VideoModel _video(String id) => VideoModel(
  id: id,
  title: id.isEmpty ? 'Invalid' : id,
  url: 'https://example.test/$id',
);

CreatorProfile _creator(String id, {String name = 'Creator'}) =>
    CreatorProfile(id: id, name: name);

import 'dart:async';

import 'package:app/database/app_database.dart';
import 'package:app/database/dao/local_library_dao.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late LocalLibraryDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.localLibraryDao;
  });

  tearDown(() async {
    await db.close();
  });

  test('creates source-scoped playlists and renames them safely', () async {
    await expectLater(
      dao.createPlaylist('source-a', '  '),
      throwsA(isA<ArgumentError>()),
    );
    await expectLater(
      dao.createPlaylist('  ', 'Queue'),
      throwsA(isA<ArgumentError>()),
    );

    final sourceAQueue = await dao.createPlaylist('source-a', 'Queue');
    final sourceBQueue = await dao.createPlaylist('source-b', 'Queue');
    expect(sourceBQueue, isNot(sourceAQueue));
    await expectLater(
      dao.createPlaylist('source-a', 'Queue'),
      throwsA(isA<Exception>()),
    );

    final oldTimestamp = DateTime.utc(2000, 1, 1);
    final target = await _insertPlaylist(
      db,
      sourceId: 'source-a',
      name: 'Other',
      timestamp: oldTimestamp,
    );

    await dao.renamePlaylist(target.internalId, 'Renamed');

    final renamed = await _getPlaylist(dao, target.internalId);
    expect(renamed.sourceId, 'source-a');
    expect(renamed.name, 'Renamed');
    expect(renamed.createdAt, oldTimestamp);
    expect(renamed.updatedAt.isAfter(oldTimestamp), isTrue);
    final renamedAt = renamed.updatedAt;

    await expectLater(
      dao.renamePlaylist(target.internalId, ' 	'),
      throwsA(isA<ArgumentError>()),
    );
    await expectLater(
      dao.renamePlaylist(target.internalId, 'Queue'),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      dao.renamePlaylist(999999, 'Missing'),
      throwsA(isA<StateError>()),
    );

    final unchanged = await _getPlaylist(dao, target.internalId);
    expect(unchanged.name, 'Renamed');
    expect(unchanged.createdAt, oldTimestamp);
    expect(unchanged.updatedAt, renamedAt);
  });

  test(
    'appends batches atomically and touches only successful writes',
    () async {
      final oldTimestamp = DateTime.utc(2000, 1, 1);
      final playlist = await _insertPlaylist(
        db,
        sourceId: 'source-a',
        name: 'Queue',
        timestamp: oldTimestamp,
      );

      await expectLater(
        dao.addPlaylistItems(
          playlistId: 999999,
          items: [_playlistItem(999999, 'source-a', 'missing')],
        ),
        throwsA(isA<StateError>()),
      );

      await dao.addPlaylistItems(
        playlistId: playlist.internalId,
        items: [
          _playlistItem(playlist.internalId, 'source-a', 'one'),
          _playlistItem(playlist.internalId, 'source-a', 'two'),
        ],
      );
      final afterAppend = await _getPlaylist(dao, playlist.internalId);
      expect(afterAppend.updatedAt.isAfter(oldTimestamp), isTrue);
      expect(
        (await dao.getPlaylistItems(playlist.internalId))
            .map((item) => item.originalId)
            .toList(),
        ['one', 'two'],
      );

      await expectLater(
        dao.addPlaylistItems(
          playlistId: playlist.internalId,
          items: [
            _playlistItem(playlist.internalId, 'source-a', 'three'),
            _playlistItem(playlist.internalId, 'source-b', 'wrong-source'),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );

      final afterRollback = await _getPlaylist(dao, playlist.internalId);
      expect(afterRollback.updatedAt, afterAppend.updatedAt);
      expect(
        (await dao.getPlaylistItems(playlist.internalId))
            .map((item) => item.originalId)
            .toList(),
        ['one', 'two'],
      );

      await dao.addPlaylistItems(playlistId: playlist.internalId, items: []);
      expect(
        (await _getPlaylist(dao, playlist.internalId)).updatedAt,
        afterAppend.updatedAt,
      );
    },
  );

  test(
    'allows duplicates, isolates sources, and cascades playlist deletion',
    () async {
      final sourceA = await dao.createPlaylist('source-a', 'Queue');
      final sourceB = await dao.createPlaylist('source-b', 'Queue');

      await dao.addPlaylistItems(
        playlistId: sourceA,
        items: [
          _playlistItem(sourceA, 'source-a', 'shared'),
          _playlistItem(sourceA, 'source-a', 'shared'),
        ],
      );
      await dao.addPlaylistItem(
        playlistId: sourceB,
        item: _playlistItem(sourceB, 'source-b', 'shared'),
      );

      final sourceAItems = await dao.getPlaylistItems(sourceA);
      final sourceBItems = await dao.getPlaylistItems(sourceB);
      expect(sourceAItems.map((item) => item.originalId).toList(), [
        'shared',
        'shared',
      ]);
      expect(sourceAItems[0].internalId, isNot(sourceAItems[1].internalId));
      expect(sourceBItems.map((item) => item.originalId).toList(), ['shared']);

      await expectLater(
        dao.addPlaylistItem(
          playlistId: sourceA,
          item: _playlistItem(sourceA, 'source-b', 'rejected'),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(await dao.getPlaylistItems(sourceA), sourceAItems);

      await dao.deletePlaylist(sourceA);
      expect(await dao.getPlaylistItems(sourceA), isEmpty);
      expect(
        (await dao.getPlaylistItems(sourceB))
            .map((item) => item.originalId)
            .toList(),
        ['shared'],
      );
    },
  );

  test(
    'appends after position gaps, compacts removals, and bounds moves',
    () async {
      final gapPlaylist = await _insertPlaylist(
        db,
        sourceId: 'source-a',
        name: 'Gapped',
        timestamp: DateTime.utc(2000, 1, 1),
      );
      final first = await _insertPlaylistItem(
        db,
        playlistId: gapPlaylist.internalId,
        sourceId: 'source-a',
        originalId: 'first',
        title: 'First',
        position: 0,
      );
      final second = await _insertPlaylistItem(
        db,
        playlistId: gapPlaylist.internalId,
        sourceId: 'source-a',
        originalId: 'second',
        title: 'Second',
        position: 2,
      );

      await dao.addPlaylistItem(
        playlistId: gapPlaylist.internalId,
        item: _playlistItem(gapPlaylist.internalId, 'source-a', 'appended'),
      );
      final appended = await dao.getPlaylistItems(gapPlaylist.internalId);
      expect(appended.map((item) => item.internalId).toList(), [
        first.internalId,
        second.internalId,
        appended.last.internalId,
      ]);
      expect(appended.map((item) => item.position).toList(), [0, 2, 3]);

      await dao.removePlaylistItem(second.internalId);
      final compacted = await dao.getPlaylistItems(gapPlaylist.internalId);
      expect(compacted.map((item) => item.position).toList(), [0, 1]);
      expect(compacted.map((item) => item.originalId).toList(), [
        'first',
        'appended',
      ]);

      final reorderPlaylist = await dao.createPlaylist('source-a', 'Reorder');
      await dao.addPlaylistItems(
        playlistId: reorderPlaylist,
        items: [
          _playlistItem(reorderPlaylist, 'source-a', 'one'),
          _playlistItem(reorderPlaylist, 'source-a', 'two'),
          _playlistItem(reorderPlaylist, 'source-a', 'one'),
          _playlistItem(reorderPlaylist, 'source-a', 'three'),
        ],
      );
      final beforeRemoval = await dao.getPlaylistItems(reorderPlaylist);
      await dao.removePlaylistItem(beforeRemoval[1].internalId);
      final afterRemoval = await dao.getPlaylistItems(reorderPlaylist);

      await dao.movePlaylistItem(
        playlistId: reorderPlaylist,
        fromIndex: 0,
        toIndex: 999,
      );
      final movedToEnd = await dao.getPlaylistItems(reorderPlaylist);
      expect(movedToEnd.map((item) => item.internalId).toList(), [
        afterRemoval[1].internalId,
        afterRemoval[2].internalId,
        afterRemoval[0].internalId,
      ]);
      expect(movedToEnd.map((item) => item.position).toList(), [0, 1, 2]);

      await dao.movePlaylistItem(
        playlistId: reorderPlaylist,
        fromIndex: 2,
        toIndex: -1,
      );
      final movedToStart = await dao.getPlaylistItems(reorderPlaylist);
      expect(movedToStart.map((item) => item.internalId).toList(), [
        afterRemoval[0].internalId,
        afterRemoval[1].internalId,
        afterRemoval[2].internalId,
      ]);

      await dao.movePlaylistItem(
        playlistId: reorderPlaylist,
        fromIndex: -1,
        toIndex: 0,
      );
      await dao.movePlaylistItem(
        playlistId: reorderPlaylist,
        fromIndex: 99,
        toIndex: 0,
      );
      expect(
        (await dao.getPlaylistItems(reorderPlaylist))
            .map((item) => item.internalId)
            .toList(),
        [
          afterRemoval[0].internalId,
          afterRemoval[1].internalId,
          afterRemoval[2].internalId,
        ],
      );
    },
  );

  test(
    'searches trimmed literal titles without escaping or scope leaks',
    () async {
      final playlist = await _insertPlaylist(
        db,
        sourceId: 'source-a',
        name: 'Searchable',
        timestamp: DateTime.utc(2000, 1, 1),
      );
      final gamma = await _insertPlaylistItem(
        db,
        playlistId: playlist.internalId,
        sourceId: 'source-a',
        originalId: 'gamma',
        title: 'Gamma video',
        position: 0,
      );
      final alphaFirst = await _insertPlaylistItem(
        db,
        playlistId: playlist.internalId,
        sourceId: 'source-a',
        originalId: 'alpha-first',
        title: 'ALPHA first',
        position: 1,
      );
      final alphaSamePosition = await _insertPlaylistItem(
        db,
        playlistId: playlist.internalId,
        sourceId: 'source-a',
        originalId: 'alpha-same-position',
        title: 'alpha same position',
        position: 1,
      );
      final alphaLater = await _insertPlaylistItem(
        db,
        playlistId: playlist.internalId,
        sourceId: 'source-a',
        originalId: 'alpha-later',
        title: 'alpha later',
        position: 2,
      );
      final percent = await _insertPlaylistItem(
        db,
        playlistId: playlist.internalId,
        sourceId: 'source-a',
        originalId: 'percent',
        title: 'literal 100% title',
        position: 3,
      );
      final underscore = await _insertPlaylistItem(
        db,
        playlistId: playlist.internalId,
        sourceId: 'source-a',
        originalId: 'underscore',
        title: 'literal underscore _ title',
        position: 4,
      );
      final backslash = await _insertPlaylistItem(
        db,
        playlistId: playlist.internalId,
        sourceId: 'source-a',
        originalId: 'backslash',
        title: 'Windows C:\\Temp guide',
        position: 5,
      );
      final chinese = await _insertPlaylistItem(
        db,
        playlistId: playlist.internalId,
        sourceId: 'source-a',
        originalId: 'chinese',
        title: '中文学习视频',
        position: 6,
      );
      final allItems = [
        gamma,
        alphaFirst,
        alphaSamePosition,
        alphaLater,
        percent,
        underscore,
        backslash,
        chinese,
      ];

      final otherPlaylist = await dao.createPlaylist('source-a', 'Other');
      final otherAlpha = await _insertPlaylistItem(
        db,
        playlistId: otherPlaylist,
        sourceId: 'source-a',
        originalId: 'other-alpha',
        title: 'alpha from another playlist',
        position: 0,
      );

      expect(
        (await dao.getPlaylistItems(
          playlist.internalId,
          query: '  AlPhA  ',
        )).map((item) => item.internalId).toList(),
        [
          alphaFirst.internalId,
          alphaSamePosition.internalId,
          alphaLater.internalId,
        ],
      );
      expect(
        (await dao.getPlaylistItems(
          playlist.internalId,
          query: '%',
        )).map((item) => item.internalId).toList(),
        [percent.internalId],
      );
      expect(
        (await dao.getPlaylistItems(
          playlist.internalId,
          query: '_',
        )).map((item) => item.internalId).toList(),
        [underscore.internalId],
      );
      expect(
        (await dao.getPlaylistItems(
          playlist.internalId,
          query: 'C:\\Temp',
        )).map((item) => item.internalId).toList(),
        [backslash.internalId],
      );
      expect(
        (await dao.getPlaylistItems(
          playlist.internalId,
          query: '学习',
        )).map((item) => item.internalId).toList(),
        [chinese.internalId],
      );
      expect(
        (await dao.getPlaylistItems(
          playlist.internalId,
          query: '',
        )).map((item) => item.internalId).toList(),
        allItems.map((item) => item.internalId).toList(),
      );
      expect(
        (await dao.getPlaylistItems(
          playlist.internalId,
          query: ' \t\n ',
        )).map((item) => item.internalId).toList(),
        allItems.map((item) => item.internalId).toList(),
      );
      expect((await dao.getPlaylistItems(999999, query: 'alpha')), isEmpty);
      expect(
        (await dao.getPlaylistItems(
          otherPlaylist,
          query: 'alpha',
        )).map((item) => item.internalId).toList(),
        [otherAlpha.internalId],
      );
    },
  );

  test('watchPlaylistItems reacts with the filtered result', () async {
    final playlist = await dao.createPlaylist('source-a', 'Reactive');
    await dao.addPlaylistItem(
      playlistId: playlist,
      item: _playlistItem(playlist, 'source-a', 'first', title: 'Alpha first'),
    );

    final iterator = StreamIterator(
      dao.watchPlaylistItems(playlist, query: ' alpha '),
    );
    addTearDown(iterator.cancel);

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.map((item) => item.originalId).toList(), ['first']);

    await dao.addPlaylistItem(
      playlistId: playlist,
      item: _playlistItem(
        playlist,
        'source-a',
        'second',
        title: 'ALPHA second',
      ),
    );

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.map((item) => item.originalId).toList(), [
      'first',
      'second',
    ]);
  });
}

Future<LocalPlaylistEntity> _insertPlaylist(
  AppDatabase db, {
  required String sourceId,
  required String name,
  required DateTime timestamp,
}) => db
    .into(db.localPlaylist)
    .insertReturning(
      LocalPlaylistCompanion.insert(
        sourceId: sourceId,
        name: name,
        createdAt: Value(timestamp),
        updatedAt: Value(timestamp),
      ),
    );

Future<LocalPlaylistEntity> _getPlaylist(
  LocalLibraryDao dao,
  int playlistId,
) async => (await dao.getPlaylists()).singleWhere(
  (playlist) => playlist.internalId == playlistId,
);

Future<LocalPlaylistItemEntity> _insertPlaylistItem(
  AppDatabase db, {
  required int playlistId,
  required String sourceId,
  required String originalId,
  required String title,
  required int position,
}) => db
    .into(db.localPlaylistItem)
    .insertReturning(
      LocalPlaylistItemCompanion.insert(
        playlistId: playlistId,
        sourceId: sourceId,
        originalId: originalId,
        title: title,
        url: 'https://example.test/$originalId',
        position: position,
      ),
    );

LocalPlaylistItemCompanion _playlistItem(
  int playlistId,
  String sourceId,
  String originalId, {
  String? title,
}) => LocalPlaylistItemCompanion.insert(
  playlistId: playlistId,
  sourceId: sourceId,
  originalId: originalId,
  title: title ?? originalId,
  url: 'https://example.test/$originalId',
  position: 0,
);

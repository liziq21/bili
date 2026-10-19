import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import 'dao/article_dao.dart';
import 'dao/creator_profile_dao.dart';
import 'dao/media_history_dao.dart';
import 'dao/local_library_dao.dart';
import 'dao/post_dao.dart';
import 'dao/recent_search_query_dao.dart';
import 'dao/video_dao.dart';
import 'table/article.dart';
import 'table/creator_profile.dart';
import 'table/media.dart';
import 'table/post.dart';
import 'table/recent_search_query.dart';
import 'table/video.dart';
import 'table/media_history.dart';
import 'table/local_library.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    RecentSearchQuery,
    Media,
    MediaHistory,
    Video,
    CreatorProfile,
    Article,
    Post,
    LocalBookmark,
    LocalPlaylist,
    LocalPlaylistItem,
    LocalSubscription,
  ],
  daos: [
    RecentSearchQueryDao,
    MediaHistoryDao,
    VideoDao,
    CreatorProfileDao,
    ArticleDao,
    PostDao,
    LocalLibraryDao,
  ],
)
class AppDatabase([QueryExecutor? queryExecutor]) extends _$AppDatabase {
  this : super(queryExecutor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (m, from, _) async {
      if (from < 2) {
        // Older databases allowed more than one history row per media. Keep
        // the newest row before adding the unique key required by progress
        // upserts; otherwise an existing user's first upgrade would fail.
        await customStatement('''
          DELETE FROM media_history
          WHERE internal_id != (
            SELECT newest.internal_id
            FROM media_history AS newest
            WHERE newest.media_id = media_history.media_id
            ORDER BY newest.accessed_at DESC, newest.internal_id DESC
            LIMIT 1
          )
        ''');
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS '
          'media_history_media_id_unique ON media_history(media_id)',
        );
      }
      if (from < 3) {
        await m.createTable(localBookmark);
        await m.createTable(localPlaylist);
        await m.createTable(localPlaylistItem);
        await m.createTable(localSubscription);
      }
      if (from < 4) {
        await m.addColumn(creatorProfile, creatorProfile.description);
        await m.addColumn(creatorProfile, creatorProfile.subscribers);
        await m.addColumn(creatorProfile, creatorProfile.videos);
      }
    },
  );

  static QueryExecutor _openConnection() {
    if (kIsWeb) {
      return driftDatabase(
        name: 'app_database',
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
        ),
      );
    }

    return driftDatabase(
      name: 'app_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}

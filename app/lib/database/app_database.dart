import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import 'dao/article_dao.dart';
import 'dao/creator_profile_dao.dart';
import 'dao/media_history_dao.dart';
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
  ],
  daos: [
    RecentSearchQueryDao,
    MediaHistoryDao,
    VideoDao,
    CreatorProfileDao,
    ArticleDao,
    PostDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? queryExecutor])
    : super(queryExecutor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
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

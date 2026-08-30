import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import 'dao/recent_search_query_dao.dart';
import 'dao/extractor_dao.dart';
import 'table/extractor.dart';
import 'table/recent_search_query.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Extractor, RecentSearchQuery],
  daos: [ExtractorDao, RecentSearchQueryDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? queryExecutor])
    : super(queryExecutor ?? _openConnection());

  @override
  int get schemaVersion => 1;

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

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'dao/recent_search_query_dao.dart';
import 'dao/extractor_dao.dart';
import 'table/extractor.dart';
import 'table/recent_search_query.dart';

part 'bili_database.g.dart';

@DriftDatabase(
  tables: [Extractor, RecentSearchQuery],
  daos: [ExtractorDao, RecentSearchQueryDao],
)
class BiliDatabase extends _$BiliDatabase {
  BiliDatabase([QueryExecutor? queryExecutor])
    : super(queryExecutor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'bili_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}

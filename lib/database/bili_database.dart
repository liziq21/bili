import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'dao/recent_search_query_dao.dart';
import 'table/recent_search_query.dart';

part 'bili_database.g.dart';

@DriftDatabase(
  tables: [RecentSearchQuery],
  daos: [RecentSearchQueryDao],
)
class BiliDatabase extends _$BiliDatabase {
  BiliDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

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

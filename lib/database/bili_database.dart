import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'dao/recent_search_query_dao.dart';
import 'model/recent_search_query_entity.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [RecentSearchQueryEntity],
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

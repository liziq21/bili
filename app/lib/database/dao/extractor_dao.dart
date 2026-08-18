import 'package:drift/drift.dart';

import '../app_database.dart';
import '../table/extractor.dart';

part 'extractor_dao.g.dart';

@DriftAccessor(tables: [Extractor])
class ExtractorDao extends DatabaseAccessor<AppDatabase>
    with _$ExtractorDaoMixin {
  ExtractorDao(super.attachedDatabase);

  Stream<List<ExtractorEntity>> getExtractorEntities(int limit) {
    return (select(extractor)
          ..orderBy([(it) => OrderingTerm(expression: it.queriedDate)])
          ..limit(limit))
        .watch();
  }

  Future<void> insertOrReplaceRecentSearch(String searchQuery) {
    return into(extractor)
        .insertOnConflictUpdate(ExtractorCompanion(name: Value(searchQuery)));
  }

  Future<void> clearRecentSearchQueries() => delete(extractor).go();
}

import 'package:drift/drift.dart';

@DataClassName('RecentSearchQueryEntity')
class RecentSearchQuery extends Table {
  TextColumn get query => text()();
  DateTimeColumn get queriedDate => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {query};
  
  @override
  String get tableName => 'recent_search_query';
  
  //@override
  //bool get isStrict => true;
}

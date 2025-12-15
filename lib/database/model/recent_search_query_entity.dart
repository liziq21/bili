import 'package:drift/drift.dart';

class RecentSearchQueryEntity extends Table {
  TextColumn get query => text().withLength(min: 6, max: 32)();
  DateTimeColumn get queriedDate => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {query};
  
  @override
  String get tableName => 'recent_search_query';
  
  //@override
  //bool get isStrict => true;
}

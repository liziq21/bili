import 'package:drift/drift.dart';

@DataClassName('RecentSearchQueryEntity')
class Extractor extends Table {
  TextColumn get name => text()();
  DateTimeColumn get queriedDate => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {name};
  
  @override
  String get tableName => 'extractor';
  
  //@override
  //bool get isStrict => true;
}

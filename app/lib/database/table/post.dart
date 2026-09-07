import 'package:drift/drift.dart';

import 'media.dart';

@DataClassName('PostEntity')
class Post extends Table {
  IntColumn get mediaId =>
      integer().references(Media, #internalId, onDelete: KeyAction.cascade)();
  TextColumn get content => text()();
  TextColumn get imageUrlsJson => text()();

  @override
  String get tableName => 'post';

  @override
  Set<Column> get primaryKey => {mediaId};
}

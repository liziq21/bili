import 'package:drift/drift.dart';

import 'media.dart';

@DataClassName('ArticleEntity')
class Article extends Table {
  IntColumn get mediaId =>
      integer().references(Media, #internalId, onDelete: KeyAction.cascade)();
  TextColumn get content => text()();
  TextColumn get author => text().nullable()();
  Int64Column get wordCount => int64().nullable()();

  @override
  String get tableName => 'article';

  @override
  Set<Column> get primaryKey => {mediaId};
}

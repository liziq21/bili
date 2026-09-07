import 'package:drift/drift.dart';

import 'media.dart';

@DataClassName('VideoEntity')
class Video extends Table {
  IntColumn get mediaId => integer().references(
    Media,
    #internalId,
    onDelete: KeyAction.cascade,
  )(); // 外键+主键
  Int64Column get duration => int64()(); // 时长（秒）
  Int64Column get viewCount => int64().nullable()(); // 观看次数

  @override
  String get tableName => 'video';

  @override
  Set<Column> get primaryKey => {mediaId};
}

import 'package:drift/drift.dart';

import 'media.dart';

@DataClassName('MediaHistoryEntity')
class MediaHistory extends Table {
  IntColumn get internalId => integer().autoIncrement()();
  IntColumn get mediaId =>
      integer().references(Media, #internalId, onDelete: KeyAction.cascade)(); // 关联任意媒体
  DateTimeColumn get accessedAt => dateTime().withDefault(currentDateAndTime)();
  Int64Column get progressSeconds => int64().nullable()(); // 进度（视频/音频有效，文章可空）
  BoolColumn get completed =>
      boolean().withDefault(const Constant(false))(); // 是否完成

  @override
  String get tableName => 'media_history';
}

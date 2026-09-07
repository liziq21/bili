import 'package:drift/drift.dart';

import '../app_database.dart';
import '../table/media.dart';
import '../table/media_history.dart';

part 'media_history_dao.g.dart';

@DriftAccessor(tables: [Media, MediaHistory])
class MediaHistoryDao extends DatabaseAccessor<AppDatabase> with _$MediaHistoryDaoMixin {
  MediaHistoryDao(super.db);

  Future<int> insertMediaHistory(Insertable<MediaHistoryEntity> entry) =>
      into(mediaHistory).insert(entry);

  // 获取带媒体信息的历史记录
  Future<List<({MediaHistoryEntity history, MediaEntity media})>> getHistoryWithMedia({int limit = 20, int offset = 0}) {
    final query = select(mediaHistory).join([
      innerJoin(media, media.internalId.equalsExp(mediaHistory.mediaId)),
    ])
    ..orderBy([OrderingTerm.desc(mediaHistory.accessedAt)])
    ..limit(limit, offset: offset);

    return query.map((row) {
      return (
        history: row.readTable(mediaHistory),
        media: row.readTable(media),
      );
    }).get();
  }
}

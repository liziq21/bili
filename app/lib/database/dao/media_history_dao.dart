import 'package:drift/drift.dart';

import '../app_database.dart';
import '../table/media.dart';
import '../table/media_history.dart';

part 'media_history_dao.g.dart';

@DriftAccessor(tables: [Media, MediaHistory])
class MediaHistoryDao(super.db)
    extends DatabaseAccessor<AppDatabase>
    with _$MediaHistoryDaoMixin {
  Future<int> insertMediaHistory(Insertable<MediaHistoryEntity> entry) =>
      into(mediaHistory).insert(entry);

  /// 保存一条媒体播放进度。upsert 语义：已有记录则更新进度，没有则插入。
  ///
  /// 用 drift 的 `insert` + `onConflict` 单语句完成，无并发双插风险。
  Future<void> saveProgress(
    int mediaId,
    int progressSeconds, {
    bool completed = false,
  }) async {
    final companion = MediaHistoryCompanion.insert(
      mediaId: mediaId,
      progressSeconds: Value(BigInt.from(progressSeconds)),
      completed: Value(completed),
    );
    await into(mediaHistory).insert(
      companion,
      onConflict: DoUpdate(
        (_) => MediaHistoryCompanion(
          completed: Value(completed),
          accessedAt: Value(DateTime.now()),
        ),
        target: [mediaHistory.mediaId],
      ),
    );
  }

  /// 按 (sourceId, originalId, type) 查找 media 行的 internalId；
  /// 不存在时插入 media + media_history 行并返回新 id。
  Future<int> getOrCreateMediaId(
    String sourceId,
    String originalId,
    String type, {
    String? title,
    String? url,
  }) async {
    final existing =
        await (select(media)..where(
              (m) =>
                  m.sourceId.equals(sourceId) &
                  m.originalId.equals(originalId) &
                  m.type.equals(type),
            ))
            .getSingleOrNull();
    if (existing != null) return existing.internalId;

    final inserted = await into(media).insertReturning(
      MediaCompanion.insert(
        sourceId: sourceId,
        originalId: originalId,
        title: title ?? originalId,
        url: url ?? '',
        type: type,
      ),
    );
    await insertMediaHistory(
      MediaHistoryCompanion.insert(mediaId: inserted.internalId),
    );
    return inserted.internalId;
  }

  /// 取指定媒体的播放进度（秒），无记录或进度为 null 时返回 null。
  Future<int?> getProgressForMedia(int mediaId) async {
    final rows = await (select(
      mediaHistory,
    )..where((h) => h.mediaId.equals(mediaId))).get();
    if (rows.isEmpty) return null;
    return rows.first.progressSeconds?.toInt();
  }

  // 获取带媒体信息的历史记录
  Future<List<({MediaHistoryEntity history, MediaEntity media})>>
  getHistoryWithMedia({int limit = 20, int offset = 0}) {
    final query =
        select(mediaHistory).join([
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

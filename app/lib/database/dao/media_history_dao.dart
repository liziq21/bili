import 'package:drift/drift.dart';

import '../app_database.dart';
import '../table/media.dart';
import '../table/media_history.dart';

part 'media_history_dao.g.dart';

typedef MediaHistoryWithMedia = ({
  MediaHistoryEntity history,
  MediaEntity media,
});

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
          progressSeconds: Value(BigInt.from(progressSeconds)),
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
    return transaction(() async {
      final mediaCompanion = MediaCompanion.insert(
        sourceId: sourceId,
        originalId: originalId,
        title: title ?? originalId,
        url: url ?? '',
        type: type,
      );
      final inserted = await into(media).insertReturning(
        mediaCompanion,
        onConflict: DoUpdate(
          (_) => MediaCompanion(
            sourceId: Value(sourceId),
            originalId: Value(originalId),
            type: Value(type),
          ),
          target: [media.sourceId, media.type, media.originalId],
        ),
      );
      await into(mediaHistory).insert(
        MediaHistoryCompanion.insert(mediaId: inserted.internalId),
        onConflict: DoUpdate(
          (_) => MediaHistoryCompanion(mediaId: Value(inserted.internalId)),
          target: [mediaHistory.mediaId],
        ),
      );
      return inserted.internalId;
    });
  }

  /// 取指定媒体的播放进度（秒），无记录或进度为 null 时返回 null。
  Future<int?> getProgressForMedia(int mediaId) async {
    final rows = await (select(
      mediaHistory,
    )..where((h) => h.mediaId.equals(mediaId))).get();
    if (rows.isEmpty) return null;
    return rows.first.progressSeconds?.toInt();
  }

  /// Gets the history rows joined with their media rows.
  Future<List<MediaHistoryWithMedia>> getHistoryWithMedia({
    int limit = 20,
    int offset = 0,
  }) => _historyWithMediaQuery(limit: limit, offset: offset).get();

  /// Watches a bounded history window joined with its media rows.
  ///
  /// The caller can request one extra row as a pagination sentinel. Keeping
  /// the query bounded lets a paginated screen react to progress saves without
  /// turning the whole history table into an unbounded stream.
  Stream<List<MediaHistoryWithMedia>> watchHistoryWithMedia({
    int limit = 20,
    int offset = 0,
  }) => _historyWithMediaQuery(limit: limit, offset: offset).watch();

  Selectable<MediaHistoryWithMedia> _historyWithMediaQuery({
    required int limit,
    required int offset,
  }) {
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
    });
  }
}

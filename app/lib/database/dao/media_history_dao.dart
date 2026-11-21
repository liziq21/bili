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
  ///
  /// 元数据是可选的：进度读取先于详情到达，此时只能拿到 id。后续带元数据的
  /// 调用会补写这些列——否则历史列表永远显示原始 id 和空白封面。
  Future<int> getOrCreateMediaId(
    String sourceId,
    String originalId,
    String type, {
    String? title,
    String? url,
    String? thumbnailUrl,
    String? creatorProfileName,
    String? creatorProfileId,
    DateTime? uploadDate,
  }) async {
    return transaction(() async {
      final mediaCompanion = MediaCompanion.insert(
        sourceId: sourceId,
        originalId: originalId,
        title: title ?? originalId,
        url: url ?? '',
        type: type,
        thumbnailUrl: Value(thumbnailUrl),
        creatorProfileName: Value(creatorProfileName),
        creatorProfileId: Value(creatorProfileId),
        uploadDate: Value(uploadDate),
      );
      final inserted = await into(media).insertReturning(
        mediaCompanion,
        onConflict: DoUpdate(
          (_) => MediaCompanion(
            sourceId: Value(sourceId),
            originalId: Value(originalId),
            type: Value(type),
            title: Value.absentIfNull(title),
            url: Value.absentIfNull(url),
            thumbnailUrl: Value.absentIfNull(thumbnailUrl),
            creatorProfileName: Value.absentIfNull(creatorProfileName),
            creatorProfileId: Value.absentIfNull(creatorProfileId),
            uploadDate: Value.absentIfNull(uploadDate),
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

  /// 按 (sourceId, originalId, type) 查 media 行的 internalId，不存在时返回 null。
  ///
  /// 读路径专用：只为恢复进度而打开视频页时不该凭空建出一条历史记录，
  /// 否则「看过」列表里会多出只有 BV 号、没有标题和封面的空条目。
  Future<int?> findMediaId(
    String sourceId,
    String originalId,
    String type,
  ) async {
    final row =
        await (select(media)..where(
              (m) =>
                  m.sourceId.equals(sourceId) &
                  m.originalId.equals(originalId) &
                  m.type.equals(type),
            ))
            .getSingleOrNull();
    return row?.internalId;
  }

  /// 取指定媒体的播放进度（秒），无记录或进度为 null 时返回 null。
  Future<int?> getProgressForMedia(int mediaId) async {
    final rows = await (select(
      mediaHistory,
    )..where((h) => h.mediaId.equals(mediaId))).get();
    if (rows.isEmpty) return null;
    return rows.first.progressSeconds?.toInt();
  }

  /// 按 `{sourceId, type, originalId}` 删除一条历史，返回删除的行数。
  ///
  /// 只删 `media_history` 行。`media` 是按 `{sourceId, type, originalId}` 共享的
  /// 元数据缓存，`video`/`article`/`post` 子行（时长、播放量、正文）挂在它下面
  /// 并随之级联。用户清的是「看过什么」，不是这些元数据；顺手删 media 会连同
  /// 子行一起带走，下次进入还得重新抓。孤儿 media 行的回收是独立议题，不在本单。
  ///
  /// 列表项只带这三个字段，不带 `media.internalId`；用子查询定位 media 行，
  /// 避免调用方为了一次删除再查一次 id。
  Future<int> deleteHistoryForMediaKey({
    required String sourceId,
    required String originalId,
    String type = Media.typeVideo,
  }) {
    final mediaIds = selectOnly(media)
      ..addColumns([media.internalId])
      ..where(
        media.sourceId.equals(sourceId) &
            media.type.equals(type) &
            media.originalId.equals(originalId),
      );
    return (delete(
      mediaHistory,
    )..where((h) => h.mediaId.isInQuery(mediaIds))).go();
  }

  /// 清空全部观看历史，返回删除的行数。
  ///
  /// 与 [deleteHistoryForMediaKey] 一样只删历史行，不动 `media` 元数据缓存。
  Future<int> clearHistory() => delete(mediaHistory).go();

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

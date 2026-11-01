import 'package:drift/drift.dart';

import '../app_database.dart';
import '../table/local_library.dart';

part 'feed_dao.g.dart';

@DriftAccessor(tables: [FeedEntry])
class FeedDao extends DatabaseAccessor<AppDatabase> with _$FeedDaoMixin {
  FeedDao(super.db);

  Future<void> upsertEntries(List<FeedEntryCompanion> entries) async {
    if (entries.isEmpty) return;
    await batch((batch) {
      for (final entry in entries) {
        batch.insert(feedEntry, entry, mode: InsertMode.insertOrReplace);
      }
    });
  }

  Future<List<FeedEntryEntity>> getEntries({
    required String sourceId,
    String? channelId,
    bool? unreadOnly,
    int? limit,
    int? offset,
  }) {
    var query = select(feedEntry)..where((e) => e.sourceId.equals(sourceId));
    if (channelId != null) {
      query = query..where((e) => e.channelId.equals(channelId));
    }
    if (unreadOnly == true) {
      query = query..where((e) => e.isRead.equals(false));
    }
    query = query..orderBy([(e) => OrderingTerm.desc(e.publishedAt)]);
    if (limit != null) query = query..limit(limit, offset: offset);
    return query.get();
  }

  Stream<List<FeedEntryEntity>> watchEntries({
    required String sourceId,
    String? channelId,
    bool? unreadOnly,
    int? limit,
  }) {
    var query = select(feedEntry)..where((e) => e.sourceId.equals(sourceId));
    if (channelId != null) {
      query = query..where((e) => e.channelId.equals(channelId));
    }
    if (unreadOnly == true) {
      query = query..where((e) => e.isRead.equals(false));
    }
    query = query..orderBy([(e) => OrderingTerm.desc(e.publishedAt)]);
    if (limit != null) query = query..limit(limit);
    return query.watch();
  }

  Future<void> markAsRead(
    String sourceId,
    String channelId,
    String entryId,
  ) async {
    await (update(feedEntry)..where(
          (e) =>
              e.sourceId.equals(sourceId) &
              e.channelId.equals(channelId) &
              e.entryId.equals(entryId),
        ))
        .write(const FeedEntryCompanion(isRead: Value(true)));
  }

  Future<void> markAllRead(String sourceId, String channelId) async {
    await (update(feedEntry)..where(
          (e) => e.sourceId.equals(sourceId) & e.channelId.equals(channelId),
        ))
        .write(const FeedEntryCompanion(isRead: Value(true)));
  }

  Future<int> getUnreadCount(String sourceId, String channelId) async {
    return (select(feedEntry)..where(
          (e) =>
              e.sourceId.equals(sourceId) &
              e.channelId.equals(channelId) &
              e.isRead.equals(false),
        ))
        .get()
        .then((rows) => rows.length);
  }

  Future<void> deleteOldEntries(
    String sourceId,
    String channelId, {
    int keepDays = 30,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: keepDays));
    await (delete(feedEntry)..where(
          (e) =>
              e.sourceId.equals(sourceId) &
              e.channelId.equals(channelId) &
              e.publishedAt.isSmallerThanValue(cutoff),
        ))
        .go();
  }
}

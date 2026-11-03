import 'package:drift/drift.dart';

import '../app_database.dart';
import '../table/local_library.dart';

part 'feed_dao.g.dart';

@DriftAccessor(tables: [FeedEntry])
class FeedDao(super.db)
    extends DatabaseAccessor<AppDatabase>
    with _$FeedDaoMixin {
  Future<void> upsertEntries(List<FeedEntryCompanion> entries) async {
    if (entries.isEmpty) return;
    for (final entry in entries) {
      _validateEntry(entry);
    }

    await transaction(() async {
      for (final entry in entries) {
        final normalized = entry.copyWith(internalId: const Value.absent());
        await into(feedEntry).insert(
          normalized,
          onConflict: DoUpdate(
            (_) => FeedEntryCompanion(
              entryType: normalized.entryType,
              title: normalized.title,
              url: normalized.url,
              thumbnailUrl: normalized.thumbnailUrl,
              creatorProfileId: normalized.creatorProfileId,
              creatorProfileName: normalized.creatorProfileName,
              publishedAt: normalized.publishedAt,
            ),
            target: [
              feedEntry.sourceId,
              feedEntry.channelId,
              feedEntry.entryId,
            ],
          ),
        );
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
    query = query
      ..orderBy([
        (e) => OrderingTerm.desc(e.publishedAt),
        (e) => OrderingTerm.desc(e.internalId),
      ]);
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
    query = query
      ..orderBy([
        (e) => OrderingTerm.desc(e.publishedAt),
        (e) => OrderingTerm.desc(e.internalId),
      ]);
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
    if (keepDays < 0) {
      throw ArgumentError.value(keepDays, 'keepDays', 'must not be negative');
    }
    final cutoff = DateTime.now().subtract(Duration(days: keepDays));
    await (delete(feedEntry)..where(
          (e) =>
              e.sourceId.equals(sourceId) &
              e.channelId.equals(channelId) &
              e.publishedAt.isSmallerThanValue(cutoff),
        ))
        .go();
  }

  void _validateEntry(FeedEntryCompanion entry) {
    _requireNonBlank(_requiredValue(entry.sourceId, 'sourceId'), 'sourceId');
    _requireNonBlank(_requiredValue(entry.channelId, 'channelId'), 'channelId');
    _requireNonBlank(_requiredValue(entry.entryId, 'entryId'), 'entryId');
    final entryType = _requiredValue(entry.entryType, 'entryType');
    if (!const {
      FeedEntry.typeVideo,
      FeedEntry.typeArticle,
      FeedEntry.typePost,
    }.contains(entryType)) {
      throw ArgumentError.value(
        entryType,
        'entryType',
        'must be video, article, or post',
      );
    }
  }

  String _requiredValue(Value<String> value, String name) {
    if (!value.present) throw ArgumentError('Missing required $name');
    return value.value;
  }

  void _requireNonBlank(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'must not be blank');
    }
  }
}

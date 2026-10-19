import 'package:drift/drift.dart';
import 'package:data/data.dart' as data;

import '../app_database.dart';
import '../table/creator_profile.dart';

part 'creator_profile_dao.g.dart';

@DriftAccessor(tables: [CreatorProfile])
class CreatorProfileDao(super.db)
    extends DatabaseAccessor<AppDatabase>
    with _$CreatorProfileDaoMixin {
  Future<int> insertCreatorProfile(Insertable<CreatorProfileEntity> entry) =>
      into(creatorProfile).insert(entry);

  Future<void> upsertCreatorProfile(Insertable<CreatorProfileEntity> entry) =>
      into(creatorProfile).insert(
        entry,
        onConflict: DoUpdate(
          (_) => entry,
          target: [creatorProfile.serviceId, creatorProfile.id],
        ),
      );

  Future<CreatorProfileEntity?> getCreatorProfile(
    String serviceId,
    String id,
  ) =>
      (select(creatorProfile)
            ..where((t) => t.serviceId.equals(serviceId) & t.id.equals(id)))
          .getSingleOrNull();

  Future<void> cacheCreatorProfile(
    String serviceId,
    data.CreatorProfile profile,
  ) => upsertCreatorProfile(
    CreatorProfileCompanion(
      serviceId: Value(serviceId),
      id: Value(profile.id),
      // Search results carry no canonical URL for every source. The URL
      // column is retained for older callers, while profile lookup is
      // keyed by service and source-local ID.
      url: const Value(''),
      name: Value(profile.name),
      thumbnailUrl: Value(profile.thumbnailUrl),
      description: Value(profile.description),
      subscribers: Value(profile.subscribers),
      videos: Value(profile.videos),
    ),
  );
}

extension CreatorProfileEntityX on CreatorProfileEntity {
  data.CreatorProfile asModel() => data.CreatorProfile(
    id: id,
    name: name,
    thumbnailUrl: thumbnailUrl,
    description: description,
    subscribers: subscribers,
    videos: videos,
  );
}

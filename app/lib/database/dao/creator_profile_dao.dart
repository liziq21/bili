import 'package:drift/drift.dart';

import '../app_database.dart';
import '../table/creator_profile.dart';

part 'creator_profile_dao.g.dart';

@DriftAccessor(tables: [CreatorProfile])
class CreatorProfileDao(super.db) extends DatabaseAccessor<AppDatabase>
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
}

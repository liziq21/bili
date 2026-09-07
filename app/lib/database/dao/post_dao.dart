import 'package:drift/drift.dart';

import '../app_database.dart';
import '../table/media.dart';
import '../table/post.dart';

part 'post_dao.g.dart';

typedef PostMediaCompanion = (MediaCompanion, PostCompanion);
typedef PostMediaEntity = (MediaEntity, PostEntity);

@DriftAccessor(tables: [Post, Media])
class PostDao extends DatabaseAccessor<AppDatabase> with _$PostDaoMixin {
  PostDao(super.db);

  /// 插入或更新图文（如果已存在相同 serviceId + originalId + type='post'，则更新）
  Future<void> insertPost(PostMediaCompanion postMedia) async {
    final (mediaCompanion, postCompanion) = postMedia;

    await transaction(() async {
      final mediaWithType = mediaCompanion.copyWith(
        type: const Value(Media.typePost),
      );

      final insertedMedia = await into(media).insertReturning(
        mediaWithType,
        onConflict: DoUpdate(
          (_) => mediaWithType,
          target: [media.sourceId, media.type, media.originalId],
        ),
      );

      await into(post).insertOnConflictUpdate(
        postCompanion.copyWith(mediaId: Value(insertedMedia.internalId)),
      );
    });
  }

  /// 根据 serviceId 和 originalId 查询图文及其媒体信息
  Future<PostMediaEntity?> getPostMedia(
    String serviceId,
    String originalId,
  ) async {
    final query =
        select(media)
            .join([innerJoin(post, post.mediaId.equalsExp(media.internalId))])
          ..where(
            media.sourceId.equals(serviceId) &
                media.originalId.equals(originalId) &
                media.type.equals(Media.typePost),
          );

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return (row.readTable(media), row.readTable(post));
  }
}

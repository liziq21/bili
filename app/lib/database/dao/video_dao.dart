import 'package:drift/drift.dart';

import '../app_database.dart';
import '../table/media.dart';
import '../table/video.dart';

part 'video_dao.g.dart';

typedef VideoMediaCompanion = (MediaCompanion, VideoCompanion);
typedef VideoMediaEntity = (MediaEntity, VideoEntity);

@DriftAccessor(tables: [Video, Media])
class VideoDao extends DatabaseAccessor<AppDatabase> with _$VideoDaoMixin {
  VideoDao(super.db);

  Future<void> insertVideo(VideoMediaCompanion videoMedia) async {
    final (mediaCompanion, videoCompanion) = videoMedia;

    await transaction(() async {
      final mediaWithType = mediaCompanion.copyWith(
        type: const Value(Media.typeVideo),
      );

      final insertedMedia = await into(media).insertReturning(
        mediaWithType,
        onConflict: DoUpdate(
          (_) => mediaWithType,
          target: [media.sourceId, media.type, media.originalId],
        ),
      );

      await into(video).insertOnConflictUpdate(
        videoCompanion.copyWith(mediaId: Value(insertedMedia.internalId)),
      );
    });
  }

  Future<VideoMediaEntity?> getVideoMedia(
    String serviceId,
    String originalId,
  ) async {
    final query =
        select(media)
            .join([innerJoin(video, video.mediaId.equalsExp(media.internalId))])
          ..where(
            media.sourceId.equals(serviceId) &
                media.originalId.equals(originalId) &
                media.type.equals(Media.typeVideo), // 使用 Media 常量
          );

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return (row.readTable(media), row.readTable(video));
  }
}

// 外部应该有类似这样的转换扩展
//
// extension VideoMediaEntityToModelMapper on VideoMediaEntity {
//   VideoModel toModel()
// }
//
// extension VideoModelMapper on VideoModel {
//   MediaCompanion toVideoMediaCompanion()
// }

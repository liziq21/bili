import 'package:drift/drift.dart';

import '../app_database.dart';
import '../table/article.dart';
import '../table/media.dart';

part 'article_dao.g.dart';

typedef ArticleMediaCompanion = (MediaCompanion, ArticleCompanion);
typedef ArticleMediaEntity = (MediaEntity, ArticleEntity);

@DriftAccessor(tables: [Article, Media])
class ArticleDao extends DatabaseAccessor<AppDatabase> with _$ArticleDaoMixin {
  ArticleDao(super.db);

  /// 插入或更新文章（如果已存在相同 serviceId + originalId + type='article'，则更新）
  Future<void> insertArticle(ArticleMediaCompanion articleMedia) async {
    final (mediaCompanion, articleCompanion) = articleMedia;

    await transaction(() async {
      final mediaWithType = mediaCompanion.copyWith(
        type: const Value(Media.typeArticle),
      );

      final insertedMedia = await into(media).insertReturning(
        mediaWithType,
        onConflict: DoUpdate(
          (_) => mediaWithType,
          target: [media.sourceId, media.type, media.originalId],
        ),
      );

      await into(article).insertOnConflictUpdate(
        articleCompanion.copyWith(mediaId: Value(insertedMedia.internalId)),
      );
    });
  }

  /// 根据 serviceId 和 originalId 查询文章及其媒体信息
  Future<ArticleMediaEntity?> getArticleMedia(
    String serviceId,
    String originalId,
  ) async {
    final query =
        select(media).join([
          innerJoin(article, article.mediaId.equalsExp(media.internalId)),
        ])..where(
          media.sourceId.equals(serviceId) &
              media.originalId.equals(originalId) &
              media.type.equals(Media.typeArticle),
        );

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return (row.readTable(media), row.readTable(article));
  }
}

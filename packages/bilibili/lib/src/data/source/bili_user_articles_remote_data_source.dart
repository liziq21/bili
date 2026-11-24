import 'package:bpi/bpi.dart';
import 'package:data/data.dart';
import 'package:model/model.dart';

import '../model/article_model.dart';
import 'bili_remote_data_source.dart';

/// B 站用户专栏文章分页桥接：`NetworkUserDataSource.getUserArticles` →
/// [UserArticlesRemoteDataSource]。
final class const BiliUserArticlesRemoteDataSource({
  required final NetworkUserDataSource network,
}) extends UserArticlesRemoteDataSource with BiliRemoteDataSource {
  @override
  Future<Result<Page<ArticleModel>, Exception>> fetchUserArticles({
    required String channelId,
    int page = 1,
    int pageSize = 30,
  }) {
    final normalizedChannelId = channelId.trim();
    final mid = int.tryParse(normalizedChannelId);
    if (mid == null || mid <= 0) {
      return Future.value(
        Result.error(
          Exception('channelId must be a positive integer id: $channelId'),
        ),
      );
    }
    if (page < 1 || pageSize < 1) {
      return Future.value(
        Result.error(Exception('page and pageSize must be positive')),
      );
    }

    return Future.sync(
      () => network.getUserArticles(mid: mid, page: page, pageSize: pageSize),
    ).then((response) {
      final items = response.articles ?? const <NetworkBiliUserArticleItem>[];
      final count = response.count;
      final totalPages = count == null
          ? (items.length < pageSize ? page : page + 1)
          : ((count + pageSize - 1) ~/ pageSize).clamp(page, 1 << 30);
      return Page<ArticleModel>(
        number: page,
        totalPages: totalPages,
        data: items.map((item) => item.asModel()).toList(),
      );
    }).toResult();
  }
}

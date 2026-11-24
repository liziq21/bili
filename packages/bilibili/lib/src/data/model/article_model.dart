import 'package:bpi/bpi.dart';
import 'package:data/data.dart';

import '../../bili_utils.dart';

extension NetworkBiliUserArticleItemX on NetworkBiliUserArticleItem {
  /// 专栏文章 → [ArticleModel]。
  ///
  /// 文章 id 在平台内以 `cv` 前缀引用，路由与去重都以它为准；`banner_url`
  /// 常为空，回落到首张正文配图。DTO 不含作者字段，作者信息由订阅表补齐。
  ArticleModel asModel() {
    final cvId = 'cv$id';
    final thumbnail = switch (imageUrls) {
      final images? when images.isNotEmpty => normalizeBiliUrl(images.first),
      _ => null,
    };
    final timestamp = publishTime ?? ctime;

    return ArticleModel(
      id: cvId,
      title: switch (title?.trim()) {
        final value? when value.isNotEmpty => value,
        _ => cvId,
      },
      url: 'https://www.bilibili.com/read/$cvId',
      thumbnailUrl: normalizeBiliUrl(bannerUrl) ?? thumbnail,
      publishedAt: timestamp == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
    );
  }
}

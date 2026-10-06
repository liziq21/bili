import 'package:json_annotation/json_annotation.dart';

import '../model/user/network_bili_user_article.dart';

/// 解析文章列表，跳过缺核心标识 `id` 的条目。
///
/// 依据 AGENTS.md「缺少核心标识的 item 必须跳过」：单条坏文章不应让整页
/// `articles` 解析失败。缺 `id` 的条目被丢弃，其余条目正常解析；缺 `title`
/// 等非核心字段的条目保留，缺失字段读为 null。
class NetworkBiliArticleListConverter
    implements JsonConverter<List<NetworkBiliUserArticleItem>?, Object?> {
  const NetworkBiliArticleListConverter();

  @override
  List<NetworkBiliUserArticleItem>? fromJson(Object? json) {
    if (json == null) return null;
    final list = json as List<dynamic>;
    final articles = <NetworkBiliUserArticleItem>[];
    for (final entry in list) {
      if (entry is! Map<String, dynamic>) continue;
      // 核心标识缺失的条目跳过，不影响整页。
      if (entry['id'] is! num) continue;
      articles.add(NetworkBiliUserArticleItem.fromJson(entry));
    }
    return articles;
  }

  @override
  Object? toJson(List<NetworkBiliUserArticleItem>? object) => object;
}

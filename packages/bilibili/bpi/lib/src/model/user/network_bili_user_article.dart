import 'package:json_annotation/json_annotation.dart';

import '../../converter/int_or_string_converter.dart';
import '../../converter/network_bili_article_list_converter.dart';

part 'network_bili_user_article.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliUserArticlesData {
  const NetworkBiliUserArticlesData({
    this.articles,
    this.pn,
    this.ps,
    this.count,
  });

  @NetworkBiliArticleListConverter()
  final List<NetworkBiliUserArticleItem>? articles;
  @NullableIntOrStringConverter()
  final int? pn;
  @NullableIntOrStringConverter()
  final int? ps;
  @NullableIntOrStringConverter()
  final int? count;

  factory NetworkBiliUserArticlesData.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliUserArticlesDataFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliUserArticleItem {
  const NetworkBiliUserArticleItem({
    required this.id,
    this.title,
    this.summary,
    this.bannerUrl,
    this.publishTime,
    this.ctime,
    this.imageUrls,
    this.stats,
  });

  final int id;
  final String? title;
  final String? summary;
  final String? bannerUrl;
  @NullableIntOrStringConverter()
  final int? publishTime;
  @NullableIntOrStringConverter()
  final int? ctime;
  final List<String>? imageUrls;
  final NetworkBiliUserArticleStats? stats;

  factory NetworkBiliUserArticleItem.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliUserArticleItemFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliUserArticleStats {
  const NetworkBiliUserArticleStats({
    this.view,
    this.favorite,
    this.like,
    this.reply,
    this.share,
    this.coin,
  });

  @NullableIntOrStringConverter()
  final int? view;
  @NullableIntOrStringConverter()
  final int? favorite;
  @NullableIntOrStringConverter()
  final int? like;
  @NullableIntOrStringConverter()
  final int? reply;
  @NullableIntOrStringConverter()
  final int? share;
  @NullableIntOrStringConverter()
  final int? coin;

  factory NetworkBiliUserArticleStats.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliUserArticleStatsFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NetworkBiliUserArticlesResponse {
  const NetworkBiliUserArticlesResponse({
    required this.code,
    required this.message,
    this.ttl,
    this.data,
  });

  final int code;
  final String message;
  @NullableIntOrStringConverter()
  final int? ttl;
  final NetworkBiliUserArticlesData? data;

  factory NetworkBiliUserArticlesResponse.fromJson(Map<String, dynamic> json) =>
      _$NetworkBiliUserArticlesResponseFromJson(json);
}

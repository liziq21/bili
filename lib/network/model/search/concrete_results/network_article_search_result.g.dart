// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_article_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NetworkArticleSearchResult _$NetworkArticleSearchResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  '_NetworkArticleSearchResult',
  json,
  ($checkedConvert) {
    final val = _NetworkArticleSearchResult(
      categoryId: $checkedConvert('category_id', (v) => (v as num).toInt()),
      categoryName: $checkedConvert('category_name', (v) => v as String),
      commentUrl: $checkedConvert('comment_url', (v) => v as String),
      desc: $checkedConvert('desc', (v) => v as String),
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      imageUrls: $checkedConvert(
        'image_urls',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      isComment: $checkedConvert('is_comment', (v) => (v as num).toInt()),
      isFold: $checkedConvert('is_fold', (v) => v as bool),
      isRk1: $checkedConvert('is_rk1', (v) => v as bool),
      like: $checkedConvert('like', (v) => (v as num).toInt()),
      mid: $checkedConvert('mid', (v) => (v as num).toInt()),
      pubTime: $checkedConvert('pub_time', (v) => (v as num).toInt()),
      rankIndex: $checkedConvert('rank_index', (v) => (v as num).toInt()),
      rankOffset: $checkedConvert('rank_offset', (v) => (v as num).toInt()),
      reply: $checkedConvert('reply', (v) => (v as num).toInt()),
      spreadId: $checkedConvert('spread_id', (v) => (v as num).toInt()),
      subType: $checkedConvert('sub_type', (v) => (v as num).toInt()),
      templateId: $checkedConvert('template_id', (v) => (v as num).toInt()),
      title: $checkedConvert('title', (v) => HtmlTitle.fromJson(v)),
      version: $checkedConvert('version', (v) => v as String),
      view: $checkedConvert('view', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'categoryId': 'category_id',
    'categoryName': 'category_name',
    'commentUrl': 'comment_url',
    'imageUrls': 'image_urls',
    'isComment': 'is_comment',
    'isFold': 'is_fold',
    'isRk1': 'is_rk1',
    'pubTime': 'pub_time',
    'rankIndex': 'rank_index',
    'rankOffset': 'rank_offset',
    'spreadId': 'spread_id',
    'subType': 'sub_type',
    'templateId': 'template_id',
  },
);

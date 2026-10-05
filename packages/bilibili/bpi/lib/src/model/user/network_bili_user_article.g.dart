// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_bili_user_article.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NetworkBiliUserArticlesData _$NetworkBiliUserArticlesDataFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBiliUserArticlesData', json, ($checkedConvert) {
  final val = NetworkBiliUserArticlesData(
    articles: $checkedConvert(
      'articles',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) =>
                NetworkBiliUserArticleItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    pn: $checkedConvert(
      'pn',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
    ps: $checkedConvert(
      'ps',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
    count: $checkedConvert(
      'count',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
  );
  return val;
});

NetworkBiliUserArticleItem _$NetworkBiliUserArticleItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'NetworkBiliUserArticleItem',
  json,
  ($checkedConvert) {
    final val = NetworkBiliUserArticleItem(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      title: $checkedConvert('title', (v) => v as String),
      summary: $checkedConvert('summary', (v) => v as String?),
      bannerUrl: $checkedConvert('banner_url', (v) => v as String?),
      publishTime: $checkedConvert(
        'publish_time',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      ctime: $checkedConvert(
        'ctime',
        (v) => const NullableIntOrStringConverter().fromJson(v),
      ),
      imageUrls: $checkedConvert(
        'image_urls',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      stats: $checkedConvert(
        'stats',
        (v) => v == null
            ? null
            : NetworkBiliUserArticleStats.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'bannerUrl': 'banner_url',
    'publishTime': 'publish_time',
    'imageUrls': 'image_urls',
  },
);

NetworkBiliUserArticleStats _$NetworkBiliUserArticleStatsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBiliUserArticleStats', json, ($checkedConvert) {
  final val = NetworkBiliUserArticleStats(
    view: $checkedConvert(
      'view',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
    favorite: $checkedConvert(
      'favorite',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
    like: $checkedConvert(
      'like',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
    reply: $checkedConvert(
      'reply',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
    share: $checkedConvert(
      'share',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
    coin: $checkedConvert(
      'coin',
      (v) => const NullableIntOrStringConverter().fromJson(v),
    ),
  );
  return val;
});

NetworkBiliUserArticlesResponse _$NetworkBiliUserArticlesResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NetworkBiliUserArticlesResponse', json, ($checkedConvert) {
  final val = NetworkBiliUserArticlesResponse(
    code: $checkedConvert('code', (v) => (v as num).toInt()),
    message: $checkedConvert('message', (v) => v as String),
    data: $checkedConvert(
      'data',
      (v) => v == null
          ? null
          : NetworkBiliUserArticlesData.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

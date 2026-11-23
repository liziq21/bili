import 'package:data/data.dart';

import '../../../bili_utils.dart';

/// Field rules shared by the simple Bilibili video feeds.
///
/// Popular and ranking both return the same item shape: a video object with
/// `owner` and `stat` sub-objects. Only the envelope, item path and pagination
/// differ, so the field rules are kept in one place.
const biliVideoFeedFields = <String, FieldMapping>{
  'id': FieldMapping(path: r'$.bvid'),
  'title': FieldMapping(path: r'$.title', fallbackPath: r'$.bvid'),
  'url': FieldMapping(path: r'$.bvid', transform: 'biliWatchUrl'),
  'thumbnailUrl': FieldMapping(path: r'$.pic', transform: 'biliUrl'),
  'viewCount': FieldMapping(path: r'$.stat.view', transform: 'int'),
  'uploadDate': FieldMapping(path: r'$.pubdate', transform: 'epochSeconds'),
  'duration': FieldMapping(path: r'$.duration', transform: 'int'),
  'creatorProfileName': FieldMapping(path: r'$.owner.name'),
  'creatorProfileId': FieldMapping(path: r'$.owner.mid', transform: 'string'),
};

const biliPopularFeedDescriptor = FeedMappingDescriptor(
  itemsPath: r'$.data.list[*]',
  schemaVersion: VideoModel.schemaVersion,
  successCodePath: r'$.code',
  successCode: 0,
  messagePath: r'$.message',
  hasMorePath: r'$.data.no_more',
  hasMoreWhen: false,
  fields: biliVideoFeedFields,
  provenance: MappingProvenance(
    generatedBy: 'hand-written',
    promptVersion: 'poc-v1',
    generatedAt: '2026-11-23',
    reviewer: 'PoC',
    fixtureHash: '676f7551',
    sourceSchemaHash: '7fb4b425',
    notes: 'Validated against the legacy popular adapter fixture.',
  ),
);

const biliRankingFeedDescriptor = FeedMappingDescriptor(
  itemsPath: r'$.data.list[*]',
  schemaVersion: VideoModel.schemaVersion,
  successCodePath: r'$.code',
  successCode: 0,
  messagePath: r'$.message',
  fields: biliVideoFeedFields,
  provenance: MappingProvenance(
    generatedBy: 'hand-written',
    promptVersion: 'poc-v1',
    generatedAt: '2026-11-23',
    reviewer: 'PoC',
    fixtureHash: '590f0408',
    sourceSchemaHash: '518bde64',
    notes: 'Validated against the legacy ranking adapter fixture.',
  ),
);

/// Field rules for the space uploads feed.
///
/// The item shape differs from popular/ranking: counts are `play`, the author
/// is `author`/`mid`, and the duration is an `mm:ss` string.
const biliUserVideoFeedFields = <String, FieldMapping>{
  'id': FieldMapping(path: r'$.bvid'),
  'title': FieldMapping(path: r'$.title', fallbackPath: r'$.bvid'),
  'url': FieldMapping(path: r'$.bvid', transform: 'biliWatchUrl'),
  'thumbnailUrl': FieldMapping(path: r'$.pic', transform: 'biliUrl'),
  'viewCount': FieldMapping(path: r'$.play', transform: 'int'),
  'uploadDate': FieldMapping(path: r'$.created', transform: 'epochSeconds'),
  'duration': FieldMapping(path: r'$.length', transform: 'parseDuration'),
  'desc': FieldMapping(path: r'$.description'),
  'creatorProfileName': FieldMapping(path: r'$.author'),
  'creatorProfileId': FieldMapping(path: r'$.mid', transform: 'string'),
};

const biliUserVideosDescriptor = FeedMappingDescriptor(
  itemsPath: r'$.data.list.vlist[*]',
  schemaVersion: VideoModel.schemaVersion,
  successCodePath: r'$.code',
  successCode: 0,
  messagePath: r'$.message',
  totalCountPath: r'$.data.page.count',
  pageSize: 30,
  fields: biliUserVideoFeedFields,
  provenance: MappingProvenance(
    generatedBy: 'hand-written',
    promptVersion: 'poc-v1',
    generatedAt: '2026-11-23',
    reviewer: 'PoC',
    fixtureHash: 'ce81e5cb',
    sourceSchemaHash: 'c83e8130',
    notes: 'Validated against the legacy user-videos adapter fixture.',
  ),
);

/// Bilibili-specific transforms layered on the neutral defaults.
final Map<String, MappingTransform> biliMappingTransforms = {
  'biliWatchUrl': (value, _) =>
      value == null ? null : buildBiliWatchUrl(value.toString()),
  'biliUrl': (value, _) => normalizeBiliUrl(value?.toString()),
};

/// Builds a canonical video item, dropping entries without a usable core ID.
VideoModel? buildBiliFeedVideoModel(Map<String, Object?> item) {
  final id = item['id'] as String?;
  final title = item['title'] as String?;
  final url = item['url'] as String?;
  if (id == null || id.isEmpty || title == null || url == null) return null;

  return VideoModel(
    id: id,
    title: title,
    url: url,
    thumbnailUrl: item['thumbnailUrl'] as String?,
    viewCount: item['viewCount'] as int?,
    uploadDate: item['uploadDate'] as DateTime?,
    duration: item['duration'] as int?,
    desc: item['desc'] as String?,
    creatorProfileName: item['creatorProfileName'] as String?,
    creatorProfileId: item['creatorProfileId'] as String?,
  );
}

DeclarativeFeedDataSource<VideoModel> createBiliPopularDeclarativeFeed({
  required FeedJsonFetcher fetchJson,
}) => DeclarativeFeedDataSource<VideoModel>(
  sourceId: 'bilibili',
  id: 'popular',
  title: '热门视频',
  descriptor: biliPopularFeedDescriptor,
  fetchJson: fetchJson,
  buildItem: buildBiliFeedVideoModel,
  transforms: MappingTransformRegistry(biliMappingTransforms),
  identityOf: (video) => video.id,
);

DeclarativeFeedDataSource<VideoModel> createBiliRankingDeclarativeFeed({
  required FeedJsonFetcher fetchJson,
}) => DeclarativeFeedDataSource<VideoModel>(
  sourceId: 'bilibili',
  id: 'ranking',
  title: '排行榜',
  descriptor: biliRankingFeedDescriptor,
  fetchJson: fetchJson,
  buildItem: buildBiliFeedVideoModel,
  transforms: MappingTransformRegistry(biliMappingTransforms),
  identityOf: (video) => video.id,
);

DeclarativeFeedDataSource<VideoModel> createBiliUserVideosDeclarativeFeed({
  required FeedJsonFetcher fetchJson,
}) => DeclarativeFeedDataSource<VideoModel>(
  sourceId: 'bilibili',
  id: 'user-videos',
  title: '用户投稿',
  descriptor: biliUserVideosDescriptor,
  fetchJson: fetchJson,
  buildItem: buildBiliFeedVideoModel,
  transforms: MappingTransformRegistry(biliMappingTransforms),
  identityOf: (video) => video.id,
);

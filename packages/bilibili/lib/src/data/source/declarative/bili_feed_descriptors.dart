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
);

const biliRankingFeedDescriptor = FeedMappingDescriptor(
  itemsPath: r'$.data.list[*]',
  schemaVersion: VideoModel.schemaVersion,
  successCodePath: r'$.code',
  successCode: 0,
  messagePath: r'$.message',
  fields: biliVideoFeedFields,
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
);

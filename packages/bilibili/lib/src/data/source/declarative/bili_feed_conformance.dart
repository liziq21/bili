import 'package:data/data.dart';

/// A stable, source-neutral snapshot of one canonical video.
///
/// Used by the mapping conformance tool and tests so that a fixture can be
/// compared against a committed golden without depending on model equality.
Map<String, Object?> canonicalVideoJson(VideoModel video) => {
  'id': video.id,
  'title': video.title,
  'url': video.url,
  'thumbnailUrl': video.thumbnailUrl,
  'viewCount': video.viewCount,
  'uploadDate': video.uploadDate?.toUtc().toIso8601String(),
  'duration': video.duration,
  'desc': video.desc,
  'creatorProfileName': video.creatorProfileName,
  'creatorProfileId': video.creatorProfileId,
};

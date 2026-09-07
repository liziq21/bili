import 'creator_profile_model.dart';
import 'paged_result.dart';
import 'video_model.dart';

class AggregateSearchPage({
  required super.number,
  required super.totalPages,
  required super.data,
  final CreatorProfile? creatorProfile,
  final List<VideoModel>? creatorProfileVideos,
}) extends Page<VideoModel>;

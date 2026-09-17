import 'creator_profile_model.dart';
import 'paged_result.dart';
import 'video_model.dart';

class AggregateSearchPage({
  required int super.number,
  required int super.totalPages,
  required List<VideoModel> super.data,
  final CreatorProfile? creatorProfile,
  final List<VideoModel>? creatorProfileVideos,
}) extends Page<VideoModel>;

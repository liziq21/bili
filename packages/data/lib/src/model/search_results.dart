import 'creator_profile_model.dart';
import 'paged_result.dart';
import 'video_model.dart';

class AggregateSearchPage extends Page<VideoModel> {
  const AggregateSearchPage({
    required super.number,
    required super.totalPages,
    required super.data,
    this.creatorProfile,
    this.creatorProfileVideos,
  });

  final CreatorProfile? creatorProfile;
  final List<VideoModel>? creatorProfileVideos;
}

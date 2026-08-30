import 'creator_profile.dart';
import 'paged_result.dart';
import 'video_info_base.dart';

class AggregateSearchPage extends Page<VideoInfoBase> {
  AggregateSearchPage({
    required super.number,
    required super.totalPages,
    required super.data,
    this.creatorProfile,
    this.creatorProfileVideos,
  });

  final CreatorProfile? creatorProfile;
  final List<VideoInfoBase>? creatorProfileVideos;
}

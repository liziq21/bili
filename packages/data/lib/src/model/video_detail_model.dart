import 'creator_profile_model.dart';
import 'video_model.dart';

final class const VideoDetail({
  required final VideoModel video,
  final CreatorProfile? creator,
  final int likeCount = 0,
  final int favoriteCount = 0,
  final int shareCount = 0,
  final bool isLiked = false,
  final bool isFavorited = false,
  final bool isSubscribed = false,
  final List<VideoModel> relatedVideos = const [],
}) {
  VideoDetail copyWith({
    VideoModel? video,
    CreatorProfile? creator,
    int? likeCount,
    int? favoriteCount,
    int? shareCount,
    bool? isLiked,
    bool? isFavorited,
    bool? isSubscribed,
    List<VideoModel>? relatedVideos,
  }) {
    return VideoDetail(
      video: video ?? this.video,
      creator: creator ?? this.creator,
      likeCount: likeCount ?? this.likeCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      shareCount: shareCount ?? this.shareCount,
      isLiked: isLiked ?? this.isLiked,
      isFavorited: isFavorited ?? this.isFavorited,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      relatedVideos: relatedVideos ?? this.relatedVideos,
    );
  }
}

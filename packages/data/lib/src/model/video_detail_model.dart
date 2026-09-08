import 'creator_profile_model.dart';
import 'video_model.dart';

final class VideoDetail {
  const VideoDetail({
    required this.video,
    this.creator,
    this.likeCount = 0,
    this.favoriteCount = 0,
    this.shareCount = 0,
    this.isLiked = false,
    this.isFavorited = false,
    this.isSubscribed = false,
    this.relatedVideos = const [],
  });

  final VideoModel video;
  final CreatorProfile? creator;
  final int likeCount;
  final int favoriteCount;
  final int shareCount;
  final bool isLiked;
  final bool isFavorited;
  final bool isSubscribed;
  final List<VideoModel> relatedVideos;

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

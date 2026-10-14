import 'creator_profile_model.dart';
import 'video_model.dart';

/// 视频章节/分 P 信息
final class const VideoChapter({
  required final int cid,
  required final int page,
  required final String title,
  required final int duration,
  final String? vid,
}) {
  factory VideoChapter.fromVideoPart(dynamic part) {
    return VideoChapter(
      cid: part.cid,
      page: part.page,
      title: part.part,
      duration: part.duration,
      vid: part.vid,
    );
  }
}

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
  final List<VideoChapter> chapters = const [],
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
    List<VideoChapter>? chapters,
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
      chapters: chapters ?? this.chapters,
    );
  }
}

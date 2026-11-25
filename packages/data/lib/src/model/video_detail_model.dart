import 'creator_profile_model.dart';
import 'video_model.dart';
import 'video_playlist_ref.dart';

/// 投稿类型：接口 `copyright` 字段的语义化取值。
enum VideoCopyright() {
  /// 自制（`copyright = 1`）。
  original,

  /// 转载（`copyright = 2`）。
  repost,
}

/// 视频章节：源给出的时间轴点（不是分 P）。
///
/// 分 P 是独立可播的媒体单元，其起点不能当作当前这一路的播放偏移，所以章节
/// 只承载「相对本片起点的秒偏移 + 标题」。
final class const VideoChapter({
  /// 相对本片起点的秒偏移，点击跳转的目标位置。
  required final int startSeconds,

  /// 章节标题。
  required final String title,
});

final class const VideoDetail({
  required final VideoModel video,
  final CreatorProfile? creator,
  final VideoCopyright? copyright,
  final int likeCount = 0,
  final int favoriteCount = 0,
  final int shareCount = 0,
  final bool isLiked = false,
  final bool isFavorited = false,
  final bool isSubscribed = false,
  final List<VideoModel> relatedVideos = const [],
  final List<VideoChapter> chapters = const [],

  /// 视频所属合集/播放列表；不属于任何合集时为 null。
  final VideoPlaylistRef? playlist,
}) {
  VideoDetail copyWith({
    VideoModel? video,
    CreatorProfile? creator,
    VideoCopyright? copyright,
    int? likeCount,
    int? favoriteCount,
    int? shareCount,
    bool? isLiked,
    bool? isFavorited,
    bool? isSubscribed,
    List<VideoModel>? relatedVideos,
    List<VideoChapter>? chapters,
    VideoPlaylistRef? playlist,
  }) {
    return VideoDetail(
      video: video ?? this.video,
      creator: creator ?? this.creator,
      copyright: copyright ?? this.copyright,
      likeCount: likeCount ?? this.likeCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      shareCount: shareCount ?? this.shareCount,
      isLiked: isLiked ?? this.isLiked,
      isFavorited: isFavorited ?? this.isFavorited,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      relatedVideos: relatedVideos ?? this.relatedVideos,
      chapters: chapters ?? this.chapters,
      playlist: playlist ?? this.playlist,
    );
  }
}

final class VideoComment {
  const VideoComment({
    required this.id,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    this.likeCount = 0,
    this.isLiked = false,
    this.createdAt,
    this.replies = const [],
  });

  final String id;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final int likeCount;
  final bool isLiked;
  final DateTime? createdAt;
  final List<VideoComment> replies;

  VideoComment copyWith({
    String? id,
    String? authorName,
    String? authorAvatar,
    String? content,
    int? likeCount,
    bool? isLiked,
    DateTime? createdAt,
    List<VideoComment>? replies,
  }) {
    return VideoComment(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      replies: replies ?? this.replies,
    );
  }
}

final class const VideoComment({
  required final String id,
  required final String authorName,
  final String? authorAvatar,
  required final String content,
  final int likeCount = 0,
  final bool isLiked = false,
  final DateTime? createdAt,
  final List<VideoComment> replies = const [],
}) {
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

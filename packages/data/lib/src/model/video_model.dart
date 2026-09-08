final class VideoModel {
  const VideoModel({
    required this.id,
    required this.title,
    required this.url,
    this.thumbnailUrl,
    this.viewCount,
    this.uploadDate,
    this.duration,
    this.desc,
    this.creatorProfileName,
    this.creatorProfileId,
  });

  final String id;
  final String title;
  final String url;
  final String? thumbnailUrl;
  final int? viewCount;
  final DateTime? uploadDate;
  final int? duration;
  final String? desc;
  final String? creatorProfileName;
  final String? creatorProfileId;
}

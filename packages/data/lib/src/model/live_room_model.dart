final class LiveRoomModel {
  const LiveRoomModel({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    this.creatorProfileName,
    this.creatorProfileId,
    this.creatorProfileAvatarUrl,
    this.viewerCount,
  });

  final String id;
  final String title;
  final String? thumbnailUrl;
  final String? creatorProfileName;
  final String? creatorProfileId;
  final String? creatorProfileAvatarUrl;
  final int? viewerCount;
}

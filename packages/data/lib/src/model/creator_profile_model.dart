class CreatorProfile {
  const CreatorProfile({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.isLive,
    this.liveRoomId,
    this.subscribers,
    this.videos,
  });

  final String id;
  final String name;
  final String? thumbnailUrl;
  final bool? isLive;
  final int? liveRoomId;
  final int? subscribers;
  final int? videos;
}

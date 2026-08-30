class CreatorProfile {
  const CreatorProfile({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    required this.isLive,
    required this.roomId,
    this.subscribers,
    this.videos,
  });

  final Object id;
  final String name;
  final String thumbnailUrl;
  final int roomId;
  final bool isLive;
  final int? subscribers;
  final int? videos;
}

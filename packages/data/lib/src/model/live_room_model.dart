final class const LiveRoomModel({
  required final int id,
  required final String title,
  required final String url,
  required final bool isLive,
  final String? thumbnailUrl,
  final String? creatorProfileName,
  final String? creatorProfileId,
}) {
  /// Version of the canonical live-room shape described by [LiveRoomModel].
  static const int schemaVersion = 1;
}

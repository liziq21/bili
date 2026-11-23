final class const VideoModel({
  required final String id,
  required final String title,
  required final String url,
  final String? thumbnailUrl,
  final int? viewCount,
  final DateTime? uploadDate,
  final int? duration,
  final String? desc,
  final String? creatorProfileName,
  final String? creatorProfileId,
}) {
  /// Version of the canonical video shape described by [VideoModel].
  ///
  /// Bump this when a field is removed or its meaning changes; declarative
  /// mapping descriptors declare the version they target.
  static const int schemaVersion = 1;

  /// Canonical fields every video mapping must produce.
  static const Set<String> requiredFields = {'id', 'title', 'url'};
}

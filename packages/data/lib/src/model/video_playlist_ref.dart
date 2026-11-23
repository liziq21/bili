import 'package:meta/meta.dart';

/// A reference to the remote playlist (Bilibili UGC season / collection) that a
/// video belongs to.
///
/// [id] is the platform playlist identifier; the exact format is owned by each
/// service source. Bilibili encodes it as `<mid>:<seasonId>` so the playlist
/// content endpoint, which requires both the owner and the season id, can be
/// called from the id alone.
@immutable
final class const VideoPlaylistRef({
  required final String id,
  required final String title,
  final String? coverUrl,
  final int? totalCount,
});

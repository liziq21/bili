import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'video_model.dart';

/// A remote playlist (collection) header plus the page of items currently known.
///
/// [items] only holds the page that was fetched; whole-playlist aggregation is
/// the job of `fetchFullPlaylist`. [totalCount] is the count advertised by the
/// source, which may exceed [items] when only the first page is loaded.
@immutable
final class const PlaylistDetail({
  required final String id,
  required final String title,
  final String? description,
  final String? coverUrl,
  final String? creatorName,
  final String? creatorId,
  final int? totalCount,
  final List<VideoModel> items = const <VideoModel>[],
}) extends Equatable {
  @override
  List<Object?> get props => [
    id,
    title,
    description,
    coverUrl,
    creatorName,
    creatorId,
    totalCount,
    items,
  ];
}

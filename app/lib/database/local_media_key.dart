import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Stable identity for a locally stored media item.
///
/// Local personalization is scoped to a source. The same original ID can
/// therefore appear in more than one source without sharing bookmarks,
/// playlist entries, or subscriptions accidentally.
@immutable
final class const LocalMediaKey(final String sourceId, final String originalId)
    with EquatableMixin {
  @override
  List<Object?> get props => [sourceId, originalId];
}

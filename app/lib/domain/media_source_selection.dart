import 'package:data/data.dart';

/// Resolves a persisted media-source id against the sources currently
/// available to the application.
///
/// A persisted id can be missing or refer to a source that is no longer
/// installed. Keeping this fallback policy in the domain layer means every
/// feature applies the same rule without depending on the provider tree.
String resolveMediaSourceId(List<MediaSource> sources, String? persisted) {
  if (persisted != null && sources.any((source) => source.id == persisted)) {
    return persisted;
  }
  return sources.isEmpty ? '' : sources.first.id;
}

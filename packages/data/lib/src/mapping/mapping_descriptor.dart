import 'package:meta/meta.dart';

/// Describes how one canonical field is read from a source item.
///
/// Exactly one of [path] or [template] is normally set. [fallbackPath] is read
/// only when the primary value is null. [transform] names an entry in a
/// mapping transform registry and receives [args].
@immutable
final class const FieldMapping({
  final String? path,
  final String? fallbackPath,
  final String? transform,
  final Map<String, Object?> args = const {},
  final String? template,
});

/// A source-neutral description of one feed page.
///
/// [itemsPath] must select a JSON list (for example `$.data.list[*]`).
/// [fields] maps canonical field names to their extraction rules. [schemaVersion]
/// declares which canonical model version the fields target. The optional
/// envelope fields decide success from the source's business code. Pagination
/// can be described either by [hasMorePath] (a boolean-style flag) or by
/// [totalCountPath] together with [pageSize].
@immutable
final class const FeedMappingDescriptor({
  required final String itemsPath,
  required final Map<String, FieldMapping> fields,
  final int schemaVersion = 1,
  final String? successCodePath,
  final int? successCode,
  final String? messagePath,
  final String? hasMorePath,
  final bool hasMoreWhen = true,
  final String? totalCountPath,
  final int? pageSize,
});

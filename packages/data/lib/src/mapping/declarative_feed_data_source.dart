import 'package:model/model.dart';

import '../model/paged_result.dart';
import '../remote_data_source.dart';
import 'json_path.dart';
import 'mapping_descriptor.dart';
import 'mapping_transform.dart';

/// Fetches one raw JSON page for a declarative feed.
typedef FeedJsonFetcher = Future<Map<String, dynamic>> Function({int? pageKey});

/// Fetches one raw JSON page using a continuation cursor.
typedef FeedJsonCursorFetcher = Future<Map<String, dynamic>> Function({
  Object? cursor,
});

/// Builds a canonical item from the descriptor-resolved field map.
///
/// Returning null drops the item, matching the API packages' rule that items
/// without a usable core ID are skipped rather than failing the whole page.
typedef FeedItemBuilder<T> = T? Function(Map<String, Object?> item);

/// Applies a [FeedMappingDescriptor] to raw JSON without any model coupling.
final class MappingEvaluator({
  required final FeedMappingDescriptor descriptor,
  final MappingTransformRegistry? transforms,
}) {
  MappingTransformRegistry get _transforms =>
      transforms ?? MappingTransformRegistry.defaultRegistry;

  /// Returns the source's failure message when its business envelope fails.
  String? validateEnvelope(Object? root) {
    final codePath = descriptor.successCodePath;
    final expected = descriptor.successCode;
    if (codePath == null || expected == null) return null;

    final actual = switch (readJsonPath(root, codePath)) {
      final int value => value,
      final num value => value.toInt(),
      final String value => int.tryParse(value),
      _ => null,
    };
    if (actual == expected) return null;

    final message = descriptor.messagePath == null
        ? null
        : readJsonPath(root, descriptor.messagePath!)?.toString();
    return message == null || message.isEmpty
        ? 'Source envelope code $actual did not match $expected'
        : message;
  }

  /// Resolves every item selected by the descriptor.
  List<Map<String, Object?>> evaluateItems(Object? root) {
    final items = readJsonPathAll(root, descriptor.itemsPath);
    return [
      for (final item in items)
        if (item is Map) evaluateItem(item),
    ];
  }

  /// Resolves one raw item into canonical field values.
  Map<String, Object?> evaluateItem(Object? raw) {
    final item = raw is Map ? raw : const <String, Object?>{};
    final resolved = <String, Object?>{};
    for (final entry in descriptor.fields.entries) {
      resolved[entry.key] = _resolveField(item, entry.value, resolved);
    }
    return resolved;
  }

  /// Whether the descriptor says another page exists.
  bool hasMore(Object? root) {
    final path = descriptor.hasMorePath;
    if (path == null) return false;
    return readJsonPath(root, path) == descriptor.hasMoreWhen;
  }

  /// The continuation cursor for the next page, or null on the last page.
  Object? nextCursor(Object? root) {
    final path = descriptor.continuationTokenPath;
    if (path == null) return null;
    final value = readJsonPath(root, path);
    if (value == null || (value is String && value.isEmpty)) return null;
    return value;
  }

  /// The total page count for [page], using the descriptor's pagination rule.
  int totalPages(Object? root, int page, {Object? nextCursor}) {
    if (descriptor.continuationTokenPath != null) {
      return nextCursor == null ? page : page + 1;
    }
    final countPath = descriptor.totalCountPath;
    final pageSize = descriptor.pageSize;
    if (countPath != null && pageSize != null && pageSize > 0) {
      final count = switch (readJsonPath(root, countPath)) {
        final int value => value,
        final num value => value.toInt(),
        final String value => int.tryParse(value),
        _ => null,
      };
      if (count != null && count > 0) {
        final total = (count + pageSize - 1) ~/ pageSize;
        return total < page ? page : total;
      }
    }
    return hasMore(root) ? page + 1 : page;
  }

  Object? _resolveField(
    Map<dynamic, dynamic> item,
    FieldMapping mapping,
    Map<String, Object?> resolved,
  ) {
    Object? value;
    if (mapping.template != null) {
      value = _expandTemplate(mapping.template!, resolved);
    } else if (mapping.path != null) {
      value = readJsonPath(item, mapping.path!);
    }
    if (value == null && mapping.fallbackPath != null) {
      value = readJsonPath(item, mapping.fallbackPath!);
    }

    final transformName = mapping.transform;
    if (transformName == null) return value;
    final transform = _transforms[transformName];
    if (transform == null) {
      throw StateError('Unknown mapping transform: $transformName');
    }
    return transform(value, mapping.args);
  }

  String _expandTemplate(String template, Map<String, Object?> resolved) {
    return template.replaceAllMapped(RegExp(r'\{(\w+)\}'), (match) {
      final value = resolved[match.group(1)];
      return value?.toString() ?? '';
    });
  }
}

/// A feed remote data source driven by a declarative descriptor.
///
/// The descriptor owns field paths, transforms, envelope checks and pagination;
/// [buildItem] is the only typed step. This keeps new simple feeds to data
/// rather than hand-written Dart, while complex sources keep their adapters.
final class DeclarativeFeedDataSource<T>({
  @override required final String sourceId,
  @override required final String id,
  @override required final String title,
  required final FeedMappingDescriptor descriptor,
  required final FeedJsonFetcher fetchJson,
  final FeedJsonCursorFetcher? fetchJsonWithCursor,
  required final FeedItemBuilder<T> buildItem,
  final MappingTransformRegistry? transforms,
  final String? Function(T item)? identityOf,
}) extends FeedRemoteDataSource<T> {
  late final MappingEvaluator _evaluator = MappingEvaluator(
    descriptor: descriptor,
    transforms: transforms,
  );

  /// The canonical model version this feed targets.
  int get schemaVersion => descriptor.schemaVersion;

  @override
  Future<Result<Page<T>, Exception>> fetchFeed({int? pageKey}) =>
      fetchFeedPage(cursor: pageKey, pageKey: pageKey);

  /// Fetches a page by continuation [cursor] and/or page number.
  ///
  /// Cursor-based sources should provide [fetchJsonWithCursor]. Page-based
  /// sources keep using [fetchJson] and pass [pageKey].
  Future<Result<Page<T>, Exception>> fetchFeedPage({
    Object? cursor,
    int? pageKey,
  }) async {
    final page = pageKey ?? (cursor is int ? cursor : 1);
    try {
      final json = fetchJsonWithCursor != null
          ? await fetchJsonWithCursor!(cursor: cursor)
          : await fetchJson(pageKey: page);
      final envelopeError = _evaluator.validateEnvelope(json);
      if (envelopeError != null) {
        return Result.error(Exception(envelopeError));
      }

      final data = <T>[];
      final seenIdentities = <String>{};
      for (final item in _evaluator.evaluateItems(json)) {
        final built = buildItem(item);
        if (built == null) continue;
        final identity = identityOf?.call(built);
        if (identity != null && !seenIdentities.add(identity)) continue;
        data.add(built);
      }

      final nextCursor = _evaluator.nextCursor(json);
      return Result.success(
        Page<T>(
          number: page,
          totalPages: _evaluator.totalPages(json, page, nextCursor: nextCursor),
          data: data,
          nextCursor: nextCursor,
        ),
      );
    } catch (error) {
      return Result.error(
        error is Exception ? error : Exception(error.toString()),
      );
    }
  }
}

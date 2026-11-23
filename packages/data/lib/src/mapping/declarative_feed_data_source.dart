import 'package:model/model.dart';

import '../model/paged_result.dart';
import '../remote_data_source.dart';
import 'json_path.dart';
import 'mapping_descriptor.dart';
import 'mapping_transform.dart';

/// Fetches one raw JSON page for a declarative feed.
typedef FeedJsonFetcher = Future<Map<String, dynamic>> Function({int? pageKey});

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
  required final FeedItemBuilder<T> buildItem,
  final MappingTransformRegistry? transforms,
}) extends FeedRemoteDataSource<T> {
  late final MappingEvaluator _evaluator = MappingEvaluator(
    descriptor: descriptor,
    transforms: transforms,
  );

  @override
  Future<Result<Page<T>, Exception>> fetchFeed({int? pageKey}) async {
    final page = pageKey ?? 1;
    try {
      final json = await fetchJson(pageKey: page);
      final envelopeError = _evaluator.validateEnvelope(json);
      if (envelopeError != null) {
        return Result.error(Exception(envelopeError));
      }

      final data = <T>[];
      for (final item in _evaluator.evaluateItems(json)) {
        final built = buildItem(item);
        if (built != null) data.add(built);
      }

      return Result.success(
        Page<T>(
          number: page,
          totalPages: _evaluator.hasMore(json) ? page + 1 : page,
          data: data,
        ),
      );
    } catch (error) {
      return Result.error(
        error is Exception ? error : Exception(error.toString()),
      );
    }
  }
}

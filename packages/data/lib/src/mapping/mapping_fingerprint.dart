import 'dart:convert';

import 'package:meta/meta.dart';

/// Records how a descriptor was produced.
///
/// This is intentionally model-agnostic: [generatedBy] can be a human, a
/// model name, or a tool. The hashes make silent fixture/schema drift visible.
@immutable
final class const MappingProvenance({
  required final String generatedBy,
  required final String promptVersion,
  required final String generatedAt,
  required final String reviewer,
  final String? fixtureHash,
  final String? sourceSchemaHash,
  final String? notes,
});

/// Content and shape fingerprints for one source fixture.
@immutable
final class const MappingFingerprint({
  required final String fixtureHash,
  required final String sourceSchemaHash,
});

/// Computes both fingerprints for a decoded JSON fixture.
MappingFingerprint fingerprintJson(Object? value) => MappingFingerprint(
  fixtureHash: mappingHash(value),
  sourceSchemaHash: mappingSchemaHash(value),
);

/// Stable hash of the canonical JSON value.
String mappingHash(Object? value) => _fnv1a(canonicalJson(value));

/// Stable hash of the fixture's key/type shape, ignoring values.
String mappingSchemaHash(Object? value) =>
    _fnv1a(canonicalJson(schemaShape(value)));

/// Encodes JSON with recursively sorted map keys so hashes ignore key order.
String canonicalJson(Object? value) => jsonEncode(_canonicalize(value));

/// Returns the key/type shape of a JSON-like value.
///
/// Lists collapse to the sorted set of their element shapes, so a list with
/// optional fields does not change the schema hash merely because one item
/// omits an optional key.
Object? schemaShape(Object? value) {
  if (value is Map) {
    final normalized = <String, Object?>{};
    for (final entry in value.entries) {
      normalized[entry.key.toString()] = entry.value;
    }
    final keys = normalized.keys.toList()..sort();
    return {for (final key in keys) key: schemaShape(normalized[key])};
  }
  if (value is Iterable) {
    if (value.isEmpty) return const ['list'];
    final shapes = <String>{};
    for (final item in value) {
      shapes.add(jsonEncode(schemaShape(item)));
    }
    final sorted = shapes.toList()..sort();
    return ['list', ...sorted.map(jsonDecode)];
  }
  return switch (value) {
    null => 'null',
    bool() => 'bool',
    int() => 'int',
    double() => 'double',
    String() => 'string',
    _ => value.runtimeType.toString(),
  };
}

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final normalized = <String, Object?>{};
    for (final entry in value.entries) {
      normalized[entry.key.toString()] = entry.value;
    }
    final keys = normalized.keys.toList()..sort();
    return {for (final key in keys) key: _canonicalize(normalized[key])};
  }
  if (value is Iterable) {
    return [for (final item in value) _canonicalize(item)];
  }
  return value;
}

String _fnv1a(String input) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(input)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

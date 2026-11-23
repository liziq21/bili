/// Minimal JSON path reader used by declarative source mappings.
///
/// Supported syntax is intentionally small: `$`, dot-separated object keys,
/// numeric list indexes, and a trailing `[*]` list selector. Filters and
/// functions are deliberately out of scope; use a mapping transform for value
/// conversion instead.
library;

Object? readJsonPath(Object? root, String expression) {
  var current = root;
  for (final segment in _segments(expression)) {
    if (segment.isEmpty) continue;
    if (segment.endsWith('[*]')) {
      final key = segment.substring(0, segment.length - 3);
      if (key.isNotEmpty) current = _readKey(current, key);
      return current;
    }
    final indexed = RegExp(r'^(.+)\[(\d+)\]$').firstMatch(segment);
    if (indexed != null) {
      final list = _readKey(current, indexed.group(1)!);
      final index = int.parse(indexed.group(2)!);
      if (list is List && index >= 0 && index < list.length) {
        current = list[index] as Object?;
        continue;
      }
      return null;
    }
    current = _readKey(current, segment);
    if (current == null) return null;
  }
  return current;
}

List<Object?> readJsonPathAll(Object? root, String expression) {
  const selector = '[*]';
  final path = expression.trim();
  if (!path.endsWith(selector)) {
    final value = readJsonPath(root, path);
    return value is List ? List<Object?>.from(value) : const [];
  }
  final value = readJsonPath(root, path.substring(0, path.length - 3));
  return value is List ? List<Object?>.from(value) : const [];
}

Iterable<String> _segments(String expression) {
  var path = expression.trim();
  if (path.startsWith(r'$')) path = path.substring(1);
  if (path.startsWith('.')) path = path.substring(1);
  if (path.isEmpty) return const [];
  return path.split('.');
}

Object? _readKey(Object? current, String key) {
  if (current is Map) {
    return current[key] as Object?;
  }
  if (current is List) {
    final index = int.tryParse(key);
    if (index != null && index >= 0 && index < current.length) {
      return current[index] as Object?;
    }
  }
  return null;
}

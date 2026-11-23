import 'package:html/parser.dart' as html_parser;

/// A deterministic value conversion usable from a declarative mapping.
///
/// [args] carries descriptor-provided configuration. Transforms must be pure:
/// the same value and args always produce the same result.
typedef MappingTransform = Object? Function(
  Object? value,
  Map<String, Object?> args,
);

/// The transform names available to a mapping descriptor.
///
/// The defaults cover source-neutral cases; a source package can add
/// source-specific transforms such as Bilibili's watch URL builder.
final class MappingTransformRegistry([
  Map<String, MappingTransform> extras = const {},
]) {
  this : _transforms = {..._defaults, ...extras};

  final Map<String, MappingTransform> _transforms;

  static final MappingTransformRegistry defaultRegistry =
      MappingTransformRegistry();

  MappingTransform? operator [](String name) => _transforms[name];

  static final Map<String, MappingTransform> _defaults = {
    'string': (value, _) => value?.toString(),
    'int': (value, _) => switch (value) {
      final int value => value,
      final num value => value.toInt(),
      final String value => int.tryParse(value),
      _ => null,
    },
    'parseCount': (value, _) => _parseCount(value),
    'parseDuration': (value, _) => _parseDuration(value),
    'epochSeconds': (value, _) {
      final seconds = switch (value) {
        final int value => value,
        final num value => value.toInt(),
        final String value => int.tryParse(value),
        _ => null,
      };
      return seconds == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    },
    'httpsUrl': (value, _) {
      final url = value?.toString();
      if (url == null || url.isEmpty) return null;
      if (url.startsWith('//')) return 'https:$url';
      if (url.startsWith('http://')) return 'https://${url.substring(7)}';
      return url;
    },
    'htmlText': (value, _) {
      final text = value?.toString();
      if (text == null || text.isEmpty) return null;
      return html_parser.parseFragment(text).text;
    },
    'pathSegment': (value, _) => value
        ?.toString()
        .replaceAll(RegExp(r'[\x00-\x1F\x7F?#/\\]'), '')
        .trim(),
  };

  static int? _parseCount(Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return null;
    final normalized = text.toLowerCase().replaceAll(',', '').trim();
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*(k|m|万|亿)?')
        .firstMatch(normalized);
    if (match == null) return null;
    final number = double.tryParse(match.group(1)!);
    if (number == null) return null;
    final multiplier = switch (match.group(2)) {
      'k' => 1e3,
      'm' => 1e6,
      '万' => 1e4,
      '亿' => 1e8,
      _ => 1.0,
    };
    return (number * multiplier).round();
  }

  static int? _parseDuration(Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return null;
    final parts = text.split(':');
    if (parts.length == 1) return int.tryParse(parts.first);
    var seconds = 0;
    for (final part in parts) {
      final component = int.tryParse(part);
      if (component == null) return null;
      seconds = seconds * 60 + component;
    }
    return seconds;
  }
}

/// Tolerant readers shared by the hand-written Bilibili DTO factories.
///
/// The platform occasionally switches an integer field to a numeric string and
/// back, so every reader accepts either shape and returns `null` for anything
/// it cannot interpret. They are internal to `bpi` and deliberately not
/// exported from `bpi.dart`.
library;

int? biliReadInt(Object? value) {
  return switch (value) {
    final int value => value,
    final num value => value.toInt(),
    final String value => int.tryParse(value),
    _ => null,
  };
}

String? biliReadString(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return value;
}

String? biliReadStringId(Object? value) {
  return switch (value) {
    final String value when value.isNotEmpty => value,
    final num value => value.toString(),
    _ => null,
  };
}

double? biliReadDouble(Object? value) {
  return switch (value) {
    final double value => value,
    final num value => value.toDouble(),
    final String value => double.tryParse(value),
    _ => null,
  };
}

T? biliReadObject<T>(
  Object? value,
  T? Function(Map<dynamic, dynamic> json) parse,
) {
  if (value is! Map) {
    return null;
  }
  return parse(value);
}

List<T> biliReadObjectList<T>(
  Object? value,
  T? Function(Map<dynamic, dynamic> json) parse,
) {
  if (value is! List) {
    return const [];
  }
  return List<T>.unmodifiable(value.whereType<Map>().map(parse).whereType<T>());
}

List<String> biliReadStringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return List<String>.unmodifiable(value.whereType<String>());
}

List<int> biliReadIntList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return List<int>.unmodifiable(value.map(biliReadInt).nonNulls);
}

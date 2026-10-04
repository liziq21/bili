import 'package:json_annotation/json_annotation.dart';

/// 把可能以数字或数字字符串出现的值读成 [String]。
class IntOrStringConverter implements JsonConverter<String, Object> {
  const IntOrStringConverter();

  @override
  String fromJson(Object json) {
    if (json is num) return json.toString();
    return json as String;
  }

  @override
  Object toJson(String object) {
    return object; // 序列化时保持原样输出为 int
  }
}

/// [IntOrStringConverter] 的可空版本，字段缺失或为 null 时返回 null。
///
/// 用于「B 站有时返回数字、有时返回数字字符串」的字段。只读不写：
/// 这些字段不对外序列化，`toJson` 不会被调用。
class NullableIntOrStringConverter implements JsonConverter<int?, Object?> {
  const NullableIntOrStringConverter();

  @override
  int? fromJson(Object? json) {
    if (json == null) return null;
    if (json is num) return json.toInt();
    if (json is String) return int.tryParse(json);
    return null;
  }

  @override
  Object? toJson(int? object) => object;
}
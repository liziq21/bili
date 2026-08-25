import 'package:json_annotation/json_annotation.dart';

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

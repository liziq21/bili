import 'package:html/parser.dart' show parse;

class HtmlTitle {
  const HtmlTitle(this.text);

  final String text;
  // Freezed will only generate a fromJson if the factory is using =>
  factory HtmlTitle.fromJson(dynamic json) {
    return HtmlTitle(json as String);
  }

  String parsedTitle() {
    return parse(text).body?.text ?? text;
  }
}

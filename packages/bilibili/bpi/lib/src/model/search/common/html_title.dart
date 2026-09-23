import 'package:html/parser.dart' show parse;

class const HtmlTitle(final String text) {
  // Freezed will only generate a fromJson if the factory is using =>
  factory HtmlTitle.fromJson(dynamic json) {
    return HtmlTitle(json as String? ?? '');
  }

  String parsedTitle() {
    if (text.isEmpty) return '';
    final parsed = parse(text).body?.text;
    final clean = (parsed != null && parsed.isNotEmpty) ? parsed : text;
    return clean.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}

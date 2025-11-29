import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:html/parser.dart' show parse;

part 'html_title.freezed.dart';
part 'html_title.g.dart';

@freezed
abstract class HtmlTitle with _$HtmlTitle {
  const HtmlTitle._();

  const factory HtmlTitle({
    required String text,
  }) = _HtmlTitle;
  
  // Freezed will only generate a fromJson if the factory is using =>
  factory HtmlTitle.fromJson(dynamic json) {
    return HtmlTitle(json as String);
  }

  String get parsedTitle {
    return parse(text).body?.text ?? text;
  }
}
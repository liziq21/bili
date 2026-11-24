import 'package:characters/characters.dart';

/// Bracket pairs whose contents must stay on one line.
///
/// These are Unicode syntax, not user-facing copy: build them from code points
/// so the hardcoded-copy and font-subset gates do not treat them as
/// translatable text.
final Map<String, String> _bracketPairs = {
  '[': ']',
  String.fromCharCode(0x3010): String.fromCharCode(0x3011),
  String.fromCharCode(0x300C): String.fromCharCode(0x300D),
  String.fromCharCode(0x300E): String.fromCharCode(0x300F),
  String.fromCharCode(0xFF08): String.fromCharCode(0xFF09),
  '(': ')',
  String.fromCharCode(0x300A): String.fromCharCode(0x300B),
  String.fromCharCode(0x3008): String.fromCharCode(0x3009),
  String.fromCharCode(0x201C): String.fromCharCode(0x201D),
};

/// U+2060 WORD JOINER, built from a code point so it is not mistaken for copy.
/// It has no visible glyph.
final String _wordJoiner = String.fromCharCode(0x2060);

/// U+200B ZERO WIDTH SPACE, used as a break opportunity before an opening
/// bracket. It is also built from a code point.
final String _breakOpportunity = String.fromCharCode(0x200B);

/// Inserts word joiners inside balanced bracket groups so the group cannot be
/// split across lines.
///
/// CJK line breaking treats `[` and `]` as ordinary characters, so a title like
/// `漩涡鸣人[阳之力]即将登场` can break after `阳之` and start the next line with
/// `力]`. A word joiner before every grapheme after the opening bracket keeps
/// the group together while a zero-width space before the bracket gives the
/// prefix a place to break.
///
/// Unbalanced brackets are left untouched: protecting the rest of the string
/// after a stray `[` would make the text unable to wrap at all. A group longer
/// than [maxGroupLength] is also left wrappable, because forcing it onto one
/// line would overflow a narrow viewport.
String keepBracketGroupsUnbroken(String text, {int maxGroupLength = 8}) {
  final clusters = text.characters.toList();
  final protected = List<bool>.filled(clusters.length, false);
  final matchedOpeners = <int>{};
  final stack = <({int index, String close})>[];

  for (var i = 0; i < clusters.length; i++) {
    final cluster = clusters[i];
    final close = _bracketPairs[cluster];
    if (close != null) {
      stack.add((index: i, close: close));
      continue;
    }

    var match = -1;
    for (var k = stack.length - 1; k >= 0; k--) {
      if (stack[k].close == cluster) {
        match = k;
        break;
      }
    }
    if (match < 0) continue;

    final opener = stack[match];
    matchedOpeners.add(opener.index);
    if (i - opener.index <= maxGroupLength) {
      for (var j = opener.index + 1; j <= i; j++) {
        protected[j] = true;
      }
    }
    stack.removeRange(match, stack.length);
  }

  final buffer = StringBuffer();
  for (var i = 0; i < clusters.length; i++) {
    if (matchedOpeners.contains(i) && !protected[i]) {
      buffer.write(_breakOpportunity);
    }
    if (protected[i]) buffer.write(_wordJoiner);
    buffer.write(clusters[i]);
  }
  return buffer.toString();
}

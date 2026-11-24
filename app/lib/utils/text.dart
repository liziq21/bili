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

/// U+2060 WORD JOINER, also built from a code point so it is not mistaken for
/// copy. It has no visible glyph.
final String _wordJoiner = String.fromCharCode(0x2060);

/// Inserts a word joiner inside balanced bracket groups so the group cannot be
/// split across lines.
///
/// CJK line breaking treats `[` and `]` as ordinary characters, so a title like
/// `漩涡鸣人[阳之力]即将登场` can break after `阳之` and start the next line with
/// `力]`. A word joiner before every character after the opening bracket keeps
/// the group together while leaving the opening bracket free to start a new
/// line.
///
/// Unbalanced brackets are left untouched: protecting the rest of the string
/// after a stray `[` would make the text unable to wrap at all.
String keepBracketGroupsUnbroken(String text) {
  final characters = text.runes.map(String.fromCharCode).toList();
  final protected = List<bool>.filled(characters.length, false);
  final open = <({int index, String close})>[];

  for (var i = 0; i < characters.length; i++) {
    final character = characters[i];
    final close = _bracketPairs[character];
    if (close != null) {
      open.add((index: i, close: close));
    } else if (open.isNotEmpty && open.last.close == character) {
      final start = open.removeLast().index;
      for (var j = start + 1; j <= i; j++) {
        protected[j] = true;
      }
    }
  }

  final buffer = StringBuffer();
  for (var i = 0; i < characters.length; i++) {
    if (protected[i]) buffer.write(_wordJoiner);
    buffer.write(characters[i]);
  }
  return buffer.toString();
}

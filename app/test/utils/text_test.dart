import 'package:app/utils/text.dart';
import 'package:flutter_test/flutter_test.dart';

final _joiner = String.fromCharCode(0x2060);

void main() {
  group('keepBracketGroupsUnbroken', () {
    test('keeps a square-bracket group on one line', () {
      // Given a title whose bracket group currently breaks after its first two
      // characters.
      // When preparing it for rendering.
      // Then every character after [ is joined to the one before it, so the
      // closing bracket cannot start a new line.
      expect(
        keepBracketGroupsUnbroken('a[bc]d'),
        'a[${_joiner}b${_joiner}c$_joiner]d',
      );
    });

    test('protects CJK and curly-quote pairs', () {
      for (final (openCode, closeCode) in [
        (0x3010, 0x3011),
        (0x300C, 0x300D),
        (0x300E, 0x300F),
        (0xFF08, 0xFF09),
        (0x300A, 0x300B),
        (0x3008, 0x3009),
        (0x201C, 0x201D),
      ]) {
        final open = String.fromCharCode(openCode);
        final close = String.fromCharCode(closeCode);
        expect(
          keepBracketGroupsUnbroken(
            'a$open'
            'bc$close'
            'd',
          ),
          'a$open${_joiner}b${_joiner}c$_joiner$close'
          'd',
          reason: 'pair U+${openCode.toRadixString(16)}',
        );
      }
    });

    test('leaves text without brackets unchanged', () {
      expect(keepBracketGroupsUnbroken('plain title 123'), 'plain title 123');
    });

    test('does not protect an unbalanced opening bracket', () {
      // A stray [ must not make the rest of the title unwrappable.
      expect(keepBracketGroupsUnbroken('a[bc'), 'a[bc');
    });

    test('protects nested groups and stops at the outer close', () {
      expect(
        keepBracketGroupsUnbroken('a[b[c]d]e'),
        'a[${_joiner}b$_joiner[${_joiner}c$_joiner]'
        '${_joiner}d$_joiner]e',
      );
    });

    test('joins every character inside the reported title group', () {
      // Given the title from the issue, built from code points so it stays out
      // of the hardcoded-copy scan.
      final title = String.fromCharCodes([
        0x6F29, 0x6DA1, 0x9E23, 0x4EBA, // 漩涡鸣人
        0x5B, // [
        0x9633, 0x4E4B, 0x529B, // 阳之力
        0x5D, // ]
        0x5373, 0x5C06, 0x767B, 0x573A, 0xFF01, // 即将登场！
      ]);

      // When preparing it for rendering.
      final result = keepBracketGroupsUnbroken(title);

      // Then the four characters after [ each carry a word joiner, including
      // the closing bracket.
      expect(result.runes.length, title.runes.length + 4);
      expect(result.contains('$_joiner]'), isTrue);
    });
  });
}

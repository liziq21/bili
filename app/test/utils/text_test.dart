import 'package:app/utils/text.dart';
import 'package:flutter_test/flutter_test.dart';

const _joiner = '\u2060';

void main() {
  group('keepBracketGroupsUnbroken', () {
    test('keeps a square-bracket group on one line', () {
      // Given a title whose bracket group currently breaks after 阳之.
      // When preparing it for rendering.
      // Then every character after [ is joined to the one before it, so the
      // closing bracket cannot start a new line.
      expect(
        keepBracketGroupsUnbroken('漩涡鸣人[阳之力]即将登场！'),
        '漩涡鸣人[$_joiner阳$_joiner之$_joiner力$_joiner]即将登场！',
      );
    });

    test('protects CJK, Latin and curly-quote pairs', () {
      for (final pair in ['【】', '「」', '『』', '（）', '()', '《》', '〈〉', '“”']) {
        final open = pair[0];
        final close = pair[1];
        expect(
          keepBracketGroupsUnbroken(
            'a$open'
            'bc$close'
            'd',
          ),
          'a$open${_joiner}b${_joiner}c$_joiner$close'
          'd',
          reason: 'pair $pair',
        );
      }
    });

    test('leaves text without brackets unchanged', () {
      expect(keepBracketGroupsUnbroken('普通标题 123'), '普通标题 123');
    });

    test('does not protect an unbalanced opening bracket', () {
      // A stray [ must not make the rest of the title unwrappable.
      expect(keepBracketGroupsUnbroken('前[未闭合标题'), '前[未闭合标题');
    });

    test('protects nested groups and stops at the outer close', () {
      expect(
        keepBracketGroupsUnbroken('【[a]】尾'),
        '【$_joiner[${_joiner}a$_joiner]$_joiner】尾',
      );
    });
  });
}

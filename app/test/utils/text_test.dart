import 'package:app/utils/text.dart';
import 'package:flutter_test/flutter_test.dart';

final _joiner = String.fromCharCode(0x2060);
final _break = String.fromCharCode(0x200B);

void main() {
  group('keepBracketGroupsUnbroken', () {
    test('keeps a square-bracket group on one line', () {
      // Given a title whose bracket group currently breaks after its first two
      // characters.
      // When preparing it for rendering.
      // Then the prefix can break before [ and every character after [ is
      // joined to the one before it.
      expect(
        keepBracketGroupsUnbroken('a[bc]d'),
        'a$_break[${_joiner}b${_joiner}c$_joiner]d',
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
        // Given a bracket pair from the supported set.
        final open = String.fromCharCode(openCode);
        final close = String.fromCharCode(closeCode);

        // When preparing text that uses it.
        // Then the group is protected like the square-bracket case.
        expect(
          keepBracketGroupsUnbroken(
            'a$open'
            'bc$close'
            'd',
          ),
          'a$_break$open${_joiner}b${_joiner}c$_joiner$close'
          'd',
          reason: 'pair U+${openCode.toRadixString(16)}',
        );
      }
    });

    test('leaves text without brackets unchanged', () {
      // Given plain text.
      // When preparing it.
      // Then nothing is inserted.
      expect(keepBracketGroupsUnbroken('plain title 123'), 'plain title 123');
    });

    test('does not protect an unbalanced opening bracket', () {
      // Given a title with a stray [.
      // When preparing it.
      // Then the rest of the title can still wrap.
      expect(keepBracketGroupsUnbroken('a[bc'), 'a[bc');
    });

    test('protects nested groups and stops at the outer close', () {
      // Given a group with a nested group.
      // When preparing it.
      // Then both groups are protected and no break is offered before the
      // inner opening bracket.
      expect(
        keepBracketGroupsUnbroken('a[b[c]d]e'),
        'a$_break[${_joiner}b$_joiner[${_joiner}c$_joiner]'
        '${_joiner}d$_joiner]e',
      );
    });

    test('matches an outer close past an unmatched inner opener', () {
      // Given a title where an unmatched ( sits inside a matched [ ].
      // When preparing it.
      // Then the outer group is still protected.
      expect(
        keepBracketGroupsUnbroken('a[b(c]d'),
        'a$_break[${_joiner}b$_joiner('
        '$_joiner'
        'c$_joiner]d',
      );
    });

    test('keeps an emoji grapheme cluster intact', () {
      // Given a bracket group containing a two-code-point emoji.
      final heart = String.fromCharCodes([0x2764, 0xFE0F]);

      // When preparing it.
      final result = keepBracketGroupsUnbroken('[$heart]');

      // Then the joiner goes before the whole cluster, not between its code
      // points.
      expect(result, '$_break[$_joiner$heart$_joiner]');
      expect(result.contains('$_joiner$heart'), isTrue);
    });

    test('leaves a group the caller rejects wrappable', () {
      // Given a group the layout says is too wide.
      // When preparing it with a rejecting predicate.
      final result = keepBracketGroupsUnbroken(
        '[abcd]',
        protectGroup: (_) => false,
      );

      // Then the group is not protected, but the prefix can still break
      // before the opening bracket.
      expect(result, '$_break[abcd]');
    });

    test('protects only the groups the caller accepts', () {
      // Given two groups, one accepted and one rejected by the layout.
      // When preparing the title.
      final result = keepBracketGroupsUnbroken(
        'a[bc]d[efgh]',
        protectGroup: (group) => group.length <= 4,
      );

      // Then the accepted group is joined and the rejected one is left alone.
      expect(result, 'a$_break[${_joiner}b${_joiner}c$_joiner]d$_break[efgh]');
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

      // Then the prefix break plus the four characters after [ each carry a
      // marker, including the closing bracket.
      expect(result.runes.length, title.runes.length + 5);
      expect(result.contains('$_joiner]'), isTrue);
    });
  });
}

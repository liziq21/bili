"""Tests for the font-subset character scanner."""

import unittest

import generate_subset_characters as subset


def scan(source: str) -> str:
    return subset._scan_string_literals(source)


class ScanStringLiteralsTest(unittest.TestCase):
    def test_plain_literal_contributes_its_text(self):
        self.assertEqual(scan("const s = '中文字';"), '中文字')

    def test_ascii_only_literal_contributes_nothing(self):
        self.assertEqual(scan("const s = 'plain';"), '')

    def test_line_comment_contributes_nothing(self):
        self.assertEqual(scan('// 中文\nconst s = "ok";'), '')

    def test_block_comment_contributes_nothing(self):
        self.assertEqual(scan('/* 中文 */ const s = "ok";'), '')

    def test_interpolation_hole_is_skipped(self):
        # Raw Python string, so the `$` reaches the scanner unescaped. The hole
        # holds non-ASCII on purpose: were it kept, the assertion would see it.
        # Only non-ASCII text survives the scan, so the surrounding spaces drop.
        self.assertEqual(scan(r"final s = '前缀 ${中文变量} 后缀';"), '前缀后缀')

    def test_dollar_before_non_ascii_is_literal_text(self):
        # `$ident` needs an ASCII identifier start, so this `$` is text: the
        # characters after it are rendered, not code.
        self.assertEqual(scan(r"final s = '前缀 $中文变量 后缀';"), '前缀中文变量后缀')

    def test_unicode_escape_is_decoded(self):
        # The contract test reads literal *values*, so an escaped character
        # needs the glyph of the character, not of the letter `u`.
        self.assertEqual(scan(r"const s = '\u4e2d';"), '中')

    def test_braced_unicode_escape_is_decoded(self):
        self.assertEqual(scan(r"const s = '\u{4e2d}';"), '中')

    def test_ascii_escape_contributes_nothing(self):
        self.assertEqual(scan(r"const s = '\n\t\x41';"), '')

    def test_raw_literal_does_not_decode_escapes(self):
        # In a raw literal `\u4e2d` is the six literal characters `u4e2d`.
        self.assertEqual(scan(r"const s = r'\u4e2d';"), '')

    def test_triple_quoted_literal_contributes_its_text(self):
        self.assertEqual(scan("const s = '''\n中文\n''';"), '中文')

    def test_triple_quoted_unicode_escape_is_decoded(self):
        self.assertEqual(scan(r"const s = '''\u4e2d''';"), '中')

    def test_multiple_literals_are_concatenated(self):
        self.assertEqual(scan("final a = '中'; final b = '文';"), '中文')


class TrackedCodePointTest(unittest.TestCase):
    def test_ascii_is_not_tracked(self):
        self.assertFalse(subset._is_tracked_code_point(0x41))

    def test_cjk_is_tracked(self):
        self.assertTrue(subset._is_tracked_code_point(0x4E2D))

    def test_astral_is_not_tracked(self):
        self.assertFalse(subset._is_tracked_code_point(0x1F44D))

    def test_surrogate_half_is_not_tracked(self):
        # An escaped astral character (`\uD83D\uDC4D`) decodes to two surrogate
        # halves; writing either one into the list raises UnicodeEncodeError.
        self.assertFalse(subset._is_tracked_code_point(0xD83D))
        self.assertFalse(subset._is_tracked_code_point(0xDC4D))


class RenderSortedTest(unittest.TestCase):
    def test_renders_code_points_in_order(self):
        self.assertEqual(subset.render_sorted({0x6587, 0x4E2D}), '中文')


if __name__ == '__main__':
    unittest.main()

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
        # Only non-ASCII text survives the scan, so the surrounding spaces drop.
        self.assertEqual(scan("final s = '前缀 \${name} 后缀';"), '前缀后缀')

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


class RenderSortedTest(unittest.TestCase):
    def test_renders_code_points_in_order(self):
        self.assertEqual(subset.render_sorted({0x6587, 0x4E2D}), '中文')


if __name__ == '__main__':
    unittest.main()

"""Unit tests for tool/generate_subset_characters.py."""

from __future__ import annotations

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import generate_subset_characters as gsc  # noqa: E402


class ScanStringLiteralsTest(unittest.TestCase):
    def test_keeps_literal_text_after_ascii_interpolation(self):
        source = "return '$placeholder亿';"

        self.assertIn('亿', gsc._scan_string_literals(source))

#!/usr/bin/env python3
"""Unit tests for tool/check_unused_arb_keys.py.

Run from the repo root:
    python3 -m unittest discover -s tool -p 'test_*.py' -v
"""

from __future__ import annotations

import io
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_unused_arb_keys as arb  # noqa: E402


def _write(path: Path, text: str) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8')
    return path


class MessageKeysTest(unittest.TestCase):
    def test_metadata_is_not_a_message(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = _write(
                Path(tmp) / 'app.arb',
                '{"@@locale": "en", "used": "x", "@used": {"description": "d"}}',
            )
            self.assertEqual(arb.message_keys(path), ['used'])

    def test_file_order_is_preserved(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = _write(Path(tmp) / 'app.arb', '{"b": "1", "a": "2"}')
            self.assertEqual(arb.message_keys(path), ['b', 'a'])


class CollectIdentifiersTest(unittest.TestCase):
    def test_generated_localization_output_is_skipped(self):
        # gen-l10n declares every key as a getter, so scanning its output would
        # report every key as referenced and the check would never fire.
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(root / 'lib' / 'a.dart', 'final value = l10n.used;')
            _write(
                root / 'lib' / arb.GENERATED_DIR / 'app_localizations.dart',
                'String get unused => "unused";',
            )
            identifiers = arb.collect_identifiers((root / 'lib',))
            self.assertIn('used', identifiers)
            self.assertNotIn('unused', identifiers)

    def test_missing_root_is_ignored(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(arb.collect_identifiers((Path(tmp) / 'nope',)), set())


class CodeOnlyTest(unittest.TestCase):
    def test_line_comment_is_blanked(self):
        self.assertNotIn('dead', arb._code_only('a // dead\nb'))
        self.assertIn('b', arb._code_only('a // dead\nb'))

    def test_block_comment_is_blanked(self):
        self.assertNotIn('dead', arb._code_only('a /* dead\nstill */ b'))
        self.assertIn('b', arb._code_only('a /* dead\nstill */ b'))

    def test_nested_block_comment_is_blanked_through_the_outer_end(self):
        # Dart nests block comments: the first `*/` closes the inner one only.
        source = 'a /* outer /* inner */ dead */ b'
        blanked = arb._code_only(source)
        self.assertNotIn('dead', blanked)
        self.assertIn('b', blanked)
        self.assertEqual(len(blanked), len(source))

    def test_plain_string_literal_is_blanked(self):
        self.assertNotIn('dead', arb._code_only("f('dead')"))
        self.assertIn('f(', arb._code_only("f('dead')"))

    def test_raw_string_literal_is_blanked(self):
        self.assertNotIn('dead', arb._code_only(r"f(r'dead\n')"))

    def test_triple_quoted_literal_is_blanked(self):
        self.assertNotIn('dead', arb._code_only("f('''dead\nmore''')"))

    def test_interpolated_literal_keeps_its_hole(self):
        # The hole is code: a key read inside it must still count.
        self.assertIn('alive', arb._code_only("f('${alive}')"))

    def test_interpolated_literal_text_is_blanked(self):
        # Only the hole is code; the surrounding text reads nothing.
        blanked = arb._code_only("f('dead ${alive}')")
        self.assertNotIn('dead', blanked)
        self.assertIn('alive', blanked)

    def test_short_interpolation_keeps_its_name(self):
        blanked = arb._code_only("f('dead $alive')")
        self.assertNotIn('dead', blanked)
        self.assertIn('alive', blanked)

    def test_escaped_dollar_is_not_interpolation(self):
        # `\$` is literal text, so nothing in the literal is code.
        blanked = arb._code_only("f('dead \\$alive')")
        self.assertNotIn('dead', blanked)
        self.assertNotIn('alive', blanked)

    def test_blanking_preserves_length(self):
        source = "a // dead\nb /* x */ c 'y'\nd 'z ${w}'"
        self.assertEqual(len(arb._code_only(source)), len(source))


class AnalyzeTest(unittest.TestCase):
    def test_reference_from_test_root_counts(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            arb_file = _write(root / 'app.arb', '{"fromLib": "1", "fromTest": "2"}')
            _write(root / 'lib' / 'a.dart', 'Text(l10n.fromLib)')
            _write(root / 'test' / 'a_test.dart', 'expect(l10n.fromTest, "2");')
            report = arb.analyze((arb_file,), (root / 'lib', root / 'test'))[0]
            self.assertEqual(report.unused, ())

    def test_comment_mention_is_not_a_reference(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            arb_file = _write(root / 'app.arb', '{"dead": "1"}')
            _write(root / 'lib' / 'a.dart', '// l10n.dead was removed\nvoid f() {}')
            report = arb.analyze((arb_file,), (root / 'lib',))[0]
            self.assertEqual(report.unused, ('dead',))

    def test_literal_mention_is_not_a_reference(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            arb_file = _write(root / 'app.arb', '{"dead": "1"}')
            _write(root / 'lib' / 'a.dart', "const name = 'dead';")
            report = arb.analyze((arb_file,), (root / 'lib',))[0]
            self.assertEqual(report.unused, ('dead',))

    def test_unreferenced_key_is_reported(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            arb_file = _write(root / 'app.arb', '{"dead": "1"}')
            _write(root / 'lib' / 'a.dart', 'Text(l10n.alive)')
            report = arb.analyze((arb_file,), (root / 'lib',))[0]
            self.assertEqual(report.unused, ('dead',))

    def test_substring_match_is_not_a_reference(self):
        # `queue.clear()` must not keep the message key `clear` alive.
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            arb_file = _write(root / 'app.arb', '{"clear": "1"}')
            _write(root / 'lib' / 'a.dart', 'void f() { queue.clearAll(); }')
            report = arb.analyze((arb_file,), (root / 'lib',))[0]
            self.assertEqual(report.unused, ('clear',))

    def test_union_deduplicates_across_locales(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            en = _write(root / 'en.arb', '{"dead": "1", "alive": "2"}')
            zh = _write(root / 'zh.arb', '{"dead": "1", "alive": "2"}')
            _write(root / 'lib' / 'a.dart', 'Text(l10n.alive)')
            reports = arb.analyze((en, zh), (root / 'lib',))
            self.assertEqual(arb.unused_keys(reports), ['dead'])


class AllowlistTest(unittest.TestCase):
    def test_comments_and_blank_lines_are_ignored(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = _write(
                Path(tmp) / 'allow.txt',
                '# header\nkept  # used by the search page in #187\n\n',
            )
            self.assertEqual(arb.load_allowlist(path), {'kept'})

    def test_missing_allowlist_is_empty(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(arb.load_allowlist(Path(tmp) / 'nope.txt'), set())


class DefaultsTest(unittest.TestCase):
    def test_package_arbs_are_checked_by_default(self):
        paths = {
            path.relative_to(arb.REPO_ROOT).as_posix()
            for path in arb.DEFAULT_ARB_FILES
        }
        self.assertIn('packages/bilibili/lib/l10n/bilibili_en.arb', paths)
        self.assertIn('packages/youtube/lib/l10n/youtube_en.arb', paths)

    def test_package_sources_are_scanned_by_default(self):
        self.assertIn(arb.REPO_ROOT / 'packages', arb.DEFAULT_ROOTS)


class MainTest(unittest.TestCase):
    def _run(self, *argv: str) -> tuple[int, str]:
        out, err = io.StringIO(), io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            code = arb.main(list(argv))
        return code, out.getvalue() + err.getvalue()

    def test_clean_tree_reports_success(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            arb_file = _write(root / 'app.arb', '{"alive": "1"}')
            _write(root / 'lib' / 'a.dart', 'Text(l10n.alive)')
            code, output = self._run(
                '--arb', str(arb_file), '--root', str(root / 'lib'),
                '--allowlist', str(root / 'allow.txt'),
            )
            self.assertEqual(code, 0)
            self.assertIn('Every message key is referenced.', output)

    def test_check_fails_on_unreferenced_key(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            arb_file = _write(root / 'app.arb', '{"dead": "1"}')
            code, output = self._run(
                '--arb', str(arb_file), '--root', str(root / 'lib'),
                '--allowlist', str(root / 'allow.txt'), '--check',
            )
            self.assertEqual(code, 1)
            self.assertIn('unused: dead', output)

    def test_check_accepts_allowlisted_key(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            arb_file = _write(root / 'app.arb', '{"dead": "1"}')
            allow = _write(root / 'allow.txt', 'dead  # kept for the next batch\n')
            code, output = self._run(
                '--arb', str(arb_file), '--root', str(root / 'lib'),
                '--allowlist', str(allow), '--check',
            )
            self.assertEqual(code, 0)
            self.assertIn('unused: dead (allowlisted)', output)

    def test_check_fails_on_stale_allowlist_entry(self):
        # The key is read again, so the exception no longer suppresses anything.
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            arb_file = _write(root / 'app.arb', '{"alive": "1"}')
            _write(root / 'lib' / 'a.dart', 'Text(l10n.alive)')
            allow = _write(root / 'allow.txt', 'alive  # was unused once\n')
            code, output = self._run(
                '--arb', str(arb_file), '--root', str(root / 'lib'),
                '--allowlist', str(allow), '--check',
            )
            self.assertEqual(code, 1)
            self.assertIn('allowlisted but referenced: alive', output)
            self.assertIn('no longer needed', output)

    def test_missing_arb_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            code, output = self._run(
                '--arb', str(Path(tmp) / 'nope.arb'), '--root', tmp,
            )
            self.assertEqual(code, 1)
            self.assertIn('file not found', output)

    def test_empty_arb_selection_fails(self):
        # A moved or renamed ARB leaves the default glob empty; that must not
        # look like a clean audit.
        with tempfile.TemporaryDirectory() as tmp:
            with mock.patch.object(arb, 'DEFAULT_ARB_FILES', ()):
                code, output = self._run('--root', tmp)
            self.assertEqual(code, 1)
            self.assertIn('No ARB files selected', output)

    def test_all_prints_referenced_and_unused(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            arb_file = _write(root / 'app.arb', '{"dead": "1", "alive": "2"}')
            _write(root / 'lib' / 'a.dart', 'Text(l10n.alive)')
            code, output = self._run(
                '--arb', str(arb_file), '--root', str(root / 'lib'),
                '--allowlist', str(root / 'allow.txt'), '--all',
            )
            self.assertEqual(code, 0)
            self.assertIn('referenced: alive', output)
            self.assertIn('unused: dead', output)


if __name__ == '__main__':
    unittest.main()

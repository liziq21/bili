"""Unit tests for tool/generate_changelog.py.

The generator's logic that is worth locking down is the bucketing (which section
a pull request lands in) and the sectioning (which release a merged pull request
belongs to). Both are pure functions over data that already exists in the
repository, so they are tested without touching the network.

Run from the repository root:
    python3 -m unittest discover -s tool -p 'test_*.py'
"""

from __future__ import annotations

import datetime as dt
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import generate_changelog as gc  # noqa: E402

UTC = dt.timezone.utc


def pr(number: int, title: str, merged_at: dt.datetime, labels=()) -> dict:
    return {
        "number": number,
        "title": title,
        "labels": list(labels),
        "merged_at": merged_at,
    }


def at(year: int, month: int, day: int, hour: int = 0) -> dt.datetime:
    return dt.datetime(year, month, day, hour, tzinfo=UTC)


class ParseIsoTest(unittest.TestCase):
    def test_z_suffix(self):
        self.assertEqual(gc.parse_iso("2026-10-14T09:00:00Z"), at(2026, 10, 14, 9))

    def test_offset_is_normalised_to_utc(self):
        self.assertEqual(gc.parse_iso("2026-10-14T11:00:00+02:00"), at(2026, 10, 14, 9))

    def test_naive_timestamp_is_treated_as_utc(self):
        self.assertEqual(gc.parse_iso("2026-10-14T09:00:00"), at(2026, 10, 14, 9))


class ParseRepoSlugTest(unittest.TestCase):
    def test_plain_owner_name(self):
        self.assertEqual(gc.parse_repo_slug("liziq21/bili"), "liziq21/bili")

    def test_https_remote(self):
        self.assertEqual(
            gc.parse_repo_slug("https://github.com/liziq21/bili.git"), "liziq21/bili"
        )

    def test_ssh_remote(self):
        self.assertEqual(gc.parse_repo_slug("git@github.com:liziq21/bili.git"), "liziq21/bili")

    def test_rejects_unparseable_value(self):
        with self.assertRaises(ValueError):
            gc.parse_repo_slug("not-a-repo")


class CategorizeTest(unittest.TestCase):
    def test_conventional_prefixes(self):
        cases = {
            "feat(app): add thing": "Added",
            "fix(home): repair thing": "Fixed",
            "docs: rewrite guide": "Documentation",
            "test(golden): record baseline": "Tests",
            "refactor(model): extract DTO": "Changed",
            "perf(search): isolate rebuild": "Changed",
            "chore(mcp): add config": "Maintenance",
            "ci: run package tests": "Maintenance",
        }
        for title, expected in cases.items():
            with self.subTest(title=title):
                self.assertEqual(gc.categorize(title, []), expected)

    def test_agent_lanes(self):
        self.assertEqual(gc.categorize("⚡ Bolt: Isolate rebuilds", []), "Changed")
        self.assertEqual(gc.categorize("🎨 Palette: Add tooltips", []), "Changed")
        self.assertEqual(gc.categorize("🛡️ Sentinel: Mask exceptions", []), "Fixed")

    def test_dependency_bumps_are_maintenance(self):
        for title in (
            "Bump the dependencies group with 5 updates",
            "Pin dependencies",
            "Update github/codeql-action action to v4",
            "Update plugin org.jetbrains.kotlin.android to v2.4.20",
            "deps: upgrade dependencies to major versions",
            "up",
        ):
            with self.subTest(title=title):
                self.assertEqual(gc.categorize(title, []), "Maintenance")

    def test_chinese_titles(self):
        cases = {
            "fix(home): 修复 HomeBloc 事件死锁": "Fixed",
            "新增搜索补全 bloc": "Added",
            "重构主页布局": "Changed",
            "补充文档规范": "Documentation",
            "补测试用例": "Tests",
            "更新依赖版本": "Maintenance",
        }
        for title, expected in cases.items():
            with self.subTest(title=title):
                self.assertEqual(gc.categorize(title, []), expected)

    def test_label_beats_title(self):
        self.assertEqual(gc.categorize("feat(x): something", ["c: infra"]), "Maintenance")
        self.assertEqual(gc.categorize("random title", ["c: feature"]), "Added")

    def test_prefix_beats_keyword(self):
        # 修复 appears in the title, but the conventional prefix is checked first.
        self.assertEqual(gc.categorize("feat(home): 修复死锁", []), "Added")

    def test_unknown_title_falls_back_to_other(self):
        self.assertEqual(gc.categorize("Redesign home feed screen", []), "Other")


class RenderEntriesTest(unittest.TestCase):
    def test_sections_render_in_declared_order(self):
        entries = [
            {"title": "d", "number": 4, "section": "Other"},
            {"title": "a", "number": 1, "section": "Added"},
            {"title": "f", "number": 2, "section": "Fixed"},
        ]
        rendered = gc.render_entries(entries)
        self.assertLess(rendered.index("### Added"), rendered.index("### Fixed"))
        self.assertLess(rendered.index("### Fixed"), rendered.index("### Other"))

    def test_empty_sections_are_omitted(self):
        entries = [{"title": "a", "number": 1, "section": "Added"}]
        rendered = gc.render_entries(entries)
        self.assertIn("### Added", rendered)
        self.assertNotIn("### Fixed", rendered)
        self.assertNotIn("### Other", rendered)

    def test_entry_format(self):
        rendered = gc.render_entries([{"title": "feat: x", "number": 7, "section": "Added"}])
        self.assertIn("- feat: x (#7)", rendered)

    def test_no_entries_renders_nothing(self):
        self.assertEqual(gc.render_entries([]), "")


class BuildDocumentTest(unittest.TestCase):
    tags = [
        ("v0.2.0", at(2026, 10, 20)),
        ("v0.1.0", at(2026, 10, 1)),
    ]

    def test_document_starts_with_preamble(self):
        document = gc.build_document([], [pr(1, "feat: x", at(2026, 10, 1))])
        self.assertTrue(document.startswith(gc.PREAMBLE))

    def test_no_tags_yields_single_unreleased_section(self):
        document = gc.build_document([], [pr(1, "feat: x", at(2026, 10, 1))])
        self.assertIn("## [Unreleased]", document)
        self.assertNotIn("## v0.1.0", document)

    def test_unreleased_comes_before_releases_and_releases_are_newest_first(self):
        document = gc.build_document(
            self.tags,
            [
                pr(1, "feat: old", at(2026, 9, 1)),
                pr(2, "feat: mid", at(2026, 10, 5)),
                pr(3, "feat: new", at(2026, 10, 25)),
            ],
        )
        self.assertLess(document.index("## [Unreleased]"), document.index("## v0.2.0"))
        self.assertLess(document.index("## v0.2.0"), document.index("## v0.1.0"))

    def test_pull_request_lands_in_the_earliest_release_after_its_merge(self):
        document = gc.build_document(
            self.tags,
            [
                pr(1, "feat: before first tag", at(2026, 9, 1)),
                pr(2, "feat: between tags", at(2026, 10, 5)),
                pr(3, "feat: after newest tag", at(2026, 10, 25)),
            ],
        )
        # Oldest tag absorbs what predates it rather than dropping it.
        self.assertIn("before first tag", document[document.index("## v0.1.0") :])
        self.assertNotIn("before first tag", document[: document.index("## v0.2.0")])
        v020 = document[document.index("## v0.2.0") : document.index("## v0.1.0")]
        self.assertIn("between tags", v020)
        self.assertNotIn("between tags", document[document.index("## v0.1.0") :])
        self.assertIn("after newest tag", document[: document.index("## v0.2.0")])

    def test_input_order_does_not_change_output(self):
        pull_requests = [
            pr(3, "feat: c", at(2026, 10, 25)),
            pr(1, "feat: a", at(2026, 9, 1)),
            pr(2, "fix: b", at(2026, 10, 5)),
        ]
        shuffled = [pull_requests[1], pull_requests[2], pull_requests[0]]
        self.assertEqual(
            gc.build_document(self.tags, pull_requests),
            gc.build_document(self.tags, shuffled),
        )

    def test_entries_are_sorted_by_merge_date(self):
        # Pull request numbers are not monotonic with merge time: a branch that
        # sat open for a month gets the higher number when it lands. Numbering
        # must not decide order. Both entries share a section, otherwise the
        # rendered section order would mask it.
        document = gc.build_document(
            [],
            [
                pr(3, "feat: merged late", at(2026, 10, 5)),
                pr(20, "feat: merged early", at(2026, 10, 1)),
            ],
        )
        self.assertLess(document.index("merged early (#20)"), document.index("merged late (#3)"))

    def test_same_timestamp_is_broken_by_pull_request_number(self):
        document = gc.build_document(
            [],
            [
                pr(9, "feat: nine", at(2026, 10, 5)),
                pr(2, "feat: two", at(2026, 10, 5)),
            ],
        )
        self.assertLess(document.index("two (#2)"), document.index("nine (#9)"))

    def test_release_with_no_pull_requests_is_omitted(self):
        document = gc.build_document(
            self.tags,
            [pr(3, "feat: after newest tag", at(2026, 10, 25))],
        )
        self.assertNotIn("## v0.2.0", document)
        self.assertNotIn("## v0.1.0", document)
        self.assertIn("## [Unreleased]", document)

    def test_empty_input_renders_preamble_only(self):
        self.assertEqual(gc.build_document([], []), gc.PREAMBLE)

    def test_is_deterministic(self):
        pull_requests = [pr(1, "feat: a", at(2026, 10, 1))]
        self.assertEqual(
            gc.build_document(self.tags, pull_requests),
            gc.build_document(self.tags, pull_requests),
        )


if __name__ == "__main__":
    unittest.main()

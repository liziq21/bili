"""Unit tests for tool/generate_changelog.py.

The generator's logic that is worth locking down is the bucketing (which section
a pull request lands in) and the sectioning (which release a merged pull request
belongs to). Both are pure functions over data that already exists in the
repository, so they are tested without touching the network.

Run from the repository root:
    python3 -m unittest discover -s tool -p 'test_*.py'
"""

from __future__ import annotations

import contextlib
import datetime as dt
import io
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
import urllib.error
import unittest.mock

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



class _FakeResponse(io.BytesIO):
    """Minimal stand-in for what `json.load` expects from urlopen."""

    def __enter__(self):
        return self

    def __exit__(self, *exc_info):
        self.close()
        return False


class _RecordingOpener:
    """Serve queued pages and remember every request the generator made."""

    def __init__(self, pages):
        self.pages = list(pages)
        self.requests: list[urllib.request.Request] = []

    def __call__(self, request, *args, **kwargs):
        self.requests.append(request)
        index = len(self.requests) - 1
        if index >= len(self.pages):
            raise AssertionError(f"unexpected request #{index + 1}: {request.full_url}")
        return _FakeResponse(json.dumps(self.pages[index]).encode("utf-8"))


def _api_item(number, merged_at, base="main", title="feat: x", labels=None):
    return {
        "number": number,
        "title": title,
        "labels": labels if labels is not None else [],
        "merged_at": merged_at,
        "base": {"ref": base},
    }


class FetchMergedPullRequestsTest(unittest.TestCase):
    """The GitHub reads: pagination, the closed/merged filter, field mapping.

    Everything here is asserted on the returned records rather than on the raw
    payloads, so a filter that silently drops a pull request shows up as a
    missing record instead of a cosmetic difference.
    """

    def _fetch(self, pages, base="main", token="secret-token"):
        opener = _RecordingOpener(pages)
        with unittest.mock.patch.object(gc.urllib.request, "urlopen", opener):
            records = gc.fetch_merged_pull_requests("liziq21/bili", token, base)
        return records, opener

    def test_closed_but_unmerged_pull_requests_are_dropped(self):
        records, _ = self._fetch(
            [
                [
                    _api_item(7, "2026-10-01T00:00:00Z"),
                    # `state=closed` also returns PRs closed without merging.
                    _api_item(8, None),
                ]
            ]
        )
        self.assertEqual([r["number"] for r in records], [7])

    def test_pull_requests_targeting_another_base_are_dropped(self):
        records, _ = self._fetch(
            [
                [
                    _api_item(7, "2026-10-01T00:00:00Z"),
                    _api_item(9, "2026-10-02T00:00:00Z", base="dev"),
                ]
            ]
        )
        self.assertEqual([r["number"] for r in records], [7])

    def test_fields_are_mapped_and_titles_trimmed(self):
        records, _ = self._fetch(
            [
                [
                    _api_item(
                        7,
                        "2026-10-01T12:00:00Z",
                        title="  feat: trimmed title  ",
                        labels=[{"name": "c: feature"}, None, {}],
                    )
                ]
            ]
        )
        self.assertEqual(
            records,
            [
                {
                    "number": 7,
                    "title": "feat: trimmed title",
                    "labels": ["c: feature", "", ""],
                    "merged_at": dt.datetime(2026, 10, 1, 12, tzinfo=UTC),
                }
            ],
        )

    def test_a_full_page_is_followed_by_the_next_one(self):
        full_page = [_api_item(n, "2026-10-01T00:00:00Z") for n in range(100, 200)]
        second_page = [_api_item(200, "2026-10-02T00:00:00Z")]
        records, opener = self._fetch([full_page, second_page])
        self.assertEqual(len(records), 101)
        self.assertEqual(len(opener.requests), 2)
        self.assertIn("page=1", opener.requests[0].full_url)
        self.assertIn("page=2", opener.requests[1].full_url)

    def test_a_short_page_ends_the_pagination(self):
        records, opener = self._fetch([[_api_item(7, "2026-10-01T00:00:00Z")]])
        self.assertEqual(len(records), 1)
        self.assertEqual(len(opener.requests), 1)

    def test_an_empty_first_page_returns_nothing(self):
        records, opener = self._fetch([[]])
        self.assertEqual(records, [])
        self.assertEqual(len(opener.requests), 1)

    def test_request_carries_the_token_and_the_filters(self):
        _, opener = self._fetch([[]], base="release")
        request = opener.requests[0]
        self.assertEqual(request.get_header("Authorization"), "Bearer secret-token")
        self.assertEqual(request.get_header("Accept"), "application/vnd.github+json")
        self.assertIn("state=closed", request.full_url)
        self.assertIn("per_page=100", request.full_url)
        self.assertIn("base=release", request.full_url)

    def test_a_non_list_payload_is_fatal(self):
        opener = _RecordingOpener([{"message": "Not Found"}])
        with unittest.mock.patch.object(gc.urllib.request, "urlopen", opener):
            with self.assertRaises(SystemExit):
                gc.fetch_merged_pull_requests("liziq21/bili", "t")

    def test_a_transport_error_is_fatal(self):
        def boom(*args, **kwargs):
            raise urllib.error.URLError("connection reset")

        with unittest.mock.patch.object(gc.urllib.request, "urlopen", boom):
            with self.assertRaises(SystemExit):
                gc.fetch_merged_pull_requests("liziq21/bili", "t")


class CollectTagsTest(unittest.TestCase):
    """Tag names decide the release sections, so their order is load-bearing."""

    @unittest.skipUnless(shutil.which("git"), "git is required for this test")
    def test_tags_are_newest_first_by_version_with_commit_dates(self):
        with tempfile.TemporaryDirectory() as repo:
            def git(*args, date="2026-10-01T00:00:00Z"):
                # The author date is deliberately a day behind the committer
                # date so the assertions pin `%cI` rather than `%aI`.
                author = (
                    dt.datetime.fromisoformat(date.replace("Z", "+00:00"))
                    - dt.timedelta(days=1)
                ).isoformat()
                env = {
                    **os.environ,
                    "GIT_AUTHOR_DATE": author,
                    "GIT_COMMITTER_DATE": date,
                }
                subprocess.run(
                    ["git", "-C", repo, *args],
                    check=True,
                    capture_output=True,
                    env=env,
                )

            git("init", "-q")
            git("config", "user.email", "test@example.com")
            git("config", "user.name", "Test")
            for index, (tag, date) in enumerate(
                [("v0.1.0", "2026-10-01T00:00:00Z"),
                 ("v0.2.0", "2026-10-02T00:00:00Z"),
                 ("v0.10.0", "2026-10-03T00:00:00Z")]
            ):
                with open(os.path.join(repo, "file.txt"), "w", encoding="utf-8") as handle:
                    handle.write(str(index))
                git("add", "file.txt")
                git("commit", "-q", "-m", f"commit {index}", date=date)
                git("tag", tag)

            tags = gc.collect_tags(repo)

        # `-v:refname` sorts v0.10.0 above v0.2.0, which a lexical sort would not.
        self.assertEqual([tag for tag, _ in tags], ["v0.10.0", "v0.2.0", "v0.1.0"])
        self.assertEqual(
            dict(tags),
            {
                "v0.10.0": dt.datetime(2026, 10, 3, tzinfo=UTC),
                "v0.2.0": dt.datetime(2026, 10, 2, tzinfo=UTC),
                "v0.1.0": dt.datetime(2026, 10, 1, tzinfo=UTC),
            },
        )


class MainTest(unittest.TestCase):
    """`main` owns the workflow contract: never rewrite an unchanged file."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.path = os.path.join(self.tmp.name, "CHANGELOG.md")

    def _run(self, pull_requests, tags=()):
        stdout = io.StringIO()
        with unittest.mock.patch.object(gc, "fetch_merged_pull_requests", return_value=pull_requests):
            with unittest.mock.patch.object(gc, "collect_tags", return_value=list(tags)):
                with unittest.mock.patch.dict(os.environ, {"GH_TOKEN": "t"}):
                    with contextlib.redirect_stdout(stdout):
                        code = gc.main(
                            [
                                "--repo",
                                "liziq21/bili",
                                "--repo-root",
                                self.tmp.name,
                            ]
                        )
        return code, stdout.getvalue()

    def test_first_run_writes_the_file(self):
        code, output = self._run([pr(7, "feat: x", at(2026, 10, 1))])
        self.assertEqual(code, 0)
        self.assertIn("wrote CHANGELOG.md", output)
        with open(self.path, encoding="utf-8") as handle:
            self.assertIn("- feat: x (#7)", handle.read())

    def test_an_unchanged_run_leaves_the_file_untouched(self):
        pull_requests = [pr(7, "feat: x", at(2026, 10, 1))]
        self._run(pull_requests)
        before = gc.build_document([], pull_requests)
        # A fixed old mtime makes the no-write check independent of how coarse
        # the filesystem's timestamps are.
        os.utime(self.path, (1_000_000, 1_000_000))

        code, output = self._run(pull_requests)

        self.assertEqual(code, 0)
        self.assertIn("is up to date", output)
        self.assertEqual(os.stat(self.path).st_mtime_ns, 1_000_000 * 10**9)
        with open(self.path, encoding="utf-8") as handle:
            self.assertEqual(handle.read(), before)

    def test_a_new_pull_request_rewrites_the_file(self):
        self._run([pr(7, "feat: x", at(2026, 10, 1))])
        code, output = self._run(
            [pr(7, "feat: x", at(2026, 10, 1)), pr(8, "fix: y", at(2026, 10, 2))]
        )
        self.assertEqual(code, 0)
        self.assertIn("wrote CHANGELOG.md", output)
        with open(self.path, encoding="utf-8") as handle:
            content = handle.read()
        self.assertIn("- feat: x (#7)", content)
        self.assertIn("- fix: y (#8)", content)

    def test_a_missing_token_fails_before_any_work(self):
        with unittest.mock.patch.dict(os.environ, {}, clear=True):
            with contextlib.redirect_stderr(io.StringIO()) as stderr:
                self.assertEqual(gc.main(["--repo", "liziq21/bili"]), 1)
        self.assertIn("GH_TOKEN", stderr.getvalue())
        self.assertFalse(os.path.exists(self.path))

if __name__ == "__main__":
    unittest.main()

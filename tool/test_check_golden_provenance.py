#!/usr/bin/env python3
"""Unit tests for tool/check_golden_provenance.py.

Run from the repo root:
    python3 -m unittest discover -s tool -p 'test_*.py' -v

The tests never touch the network; ``FakeApi`` stands in for the GitHub API.
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_golden_provenance as provenance  # noqa: E402

GOLDEN = 'app/test/golden/goldens/ci/home_screen.png'
OTHER_GOLDEN = 'app/test/golden/goldens/ci/dark_theme.png'
RERECORD = provenance.RERECORD_WORKFLOW
MATCHING_BLOB = 'a' * 40
SWAPPED_BLOB = 'b' * 40


class FakeApi:
    def __init__(
        self,
        files: list[provenance.PullFile] | None = None,
        commits: dict[str, list[str]] | None = None,
        parents: dict[str, list[str]] | None = None,
        runs: dict[str, list[provenance.WorkflowRun]] | None = None,
        artifacts: dict[int, dict[str, str] | None] | None = None,
        file_blobs: dict[tuple[str, str], str] | None = None,
        recent: list[provenance.WorkflowRun] | None = None,
        ancestor_pairs: set[tuple[str, str]] | None = None,
    ) -> None:
        self.files = files or []
        self.commits = commits or {}
        self._parents = parents or {}
        self.runs = runs or {}
        self.artifacts = artifacts or {}
        self.file_blobs = file_blobs or {}
        self.recent = recent or []
        self.ancestor_pairs = ancestor_pairs or set()
        self.artifact_requests: list[int] = []
        self.run_requests: list[str] = []

    def pull_files(self, pr: int) -> list[provenance.PullFile]:
        return self.files

    def commits_touching(self, path: str, ref: str) -> list[str]:
        return self.commits.get(path, [])

    def parents(self, sha: str) -> list[str]:
        return self._parents.get(sha, [])

    def runs_for_head(self, sha: str) -> list[provenance.WorkflowRun]:
        self.run_requests.append(sha)
        return self.runs.get(sha, [])

    def recent_runs(self) -> list[provenance.WorkflowRun]:
        return self.recent

    def is_ancestor(self, ancestor: str, descendant: str) -> bool:
        if ancestor == descendant:
            return True
        return (ancestor, descendant) in self.ancestor_pairs

    def file_blob(self, path: str, ref: str) -> str | None:
        return self.file_blobs.get((path, ref))

    def artifact_blobs(self, run_id: int) -> dict[str, str] | None:
        self.artifact_requests.append(run_id)
        return self.artifacts.get(run_id)


def _run(run_id: int = 1, conclusion: str | None = 'success') -> provenance.WorkflowRun:
    return provenance.WorkflowRun(
        id=run_id,
        head_sha='run-head',
        conclusion=conclusion,
        path=RERECORD,
        html_url=f'https://example.test/runs/{run_id}',
    )


def _problems(
    api: FakeApi,
    depth: int = provenance.ANCESTOR_DEPTH,
    base: str | None = None,
):
    return provenance.check_provenance(api, 1, 'head', base, depth).problems


def _golden(path: str = GOLDEN, blob: str = MATCHING_BLOB,
            status: str = 'added') -> provenance.PullFile:
    return provenance.PullFile(path=path, status=status, blob_sha=blob)


class GitBlobShaTest(unittest.TestCase):
    def test_matches_git_hash_object(self):
        # `printf 'hello\n' | git hash-object --stdin`
        self.assertEqual(
            provenance.git_blob_sha(b'hello\n'),
            'ce013625030ba8dba906f756967f9e9ca394464a',
        )

    def test_distinguishes_different_bytes(self):
        self.assertNotEqual(
            provenance.git_blob_sha(b'\x89PNG-A'),
            provenance.git_blob_sha(b'\x89PNG-B'),
        )


class ArtifactEntryMatchTest(unittest.TestCase):
    def test_upload_root_prefix_is_accepted(self):
        self.assertTrue(
            provenance.artifact_entry_matches('goldens/ci/home_screen.png', GOLDEN)
        )

    def test_full_repository_path_is_accepted(self):
        self.assertTrue(provenance.artifact_entry_matches(GOLDEN, GOLDEN))

    def test_other_file_is_rejected(self):
        self.assertFalse(
            provenance.artifact_entry_matches('goldens/ci/dark_theme.png', GOLDEN)
        )

    def test_similar_suffix_is_rejected(self):
        self.assertFalse(
            provenance.artifact_entry_matches(
                'goldens/ci/old_home_screen.png', GOLDEN
            )
        )


class GoldenPngTest(unittest.TestCase):
    def test_only_ci_golden_pngs_are_checked(self):
        self.assertTrue(provenance.is_golden_png(GOLDEN))
        self.assertFalse(
            provenance.is_golden_png('app/test/golden/failures/home_screen.png')
        )
        self.assertFalse(provenance.is_golden_png('app/test/golden/goldens/ci/x.txt'))


class FindUnprovenancedTest(unittest.TestCase):
    def test_ignores_pull_requests_without_golden_changes(self):
        api = FakeApi(files=[provenance.PullFile('app/lib/main.dart', 'modified', 'c' * 40)])
        self.assertEqual(_problems(api), [])

    def test_ignores_deleted_goldens(self):
        api = FakeApi(files=[_golden(status='removed')])
        self.assertEqual(_problems(api), [])

    def test_matching_artifact_proves_provenance(self):
        api = FakeApi(
            files=[_golden()],
            commits={GOLDEN: ['record-commit']},
            parents={'record-commit': ['run-head']},
            runs={'run-head': [_run(7)]},
            artifacts={7: {'goldens/ci/home_screen.png': MATCHING_BLOB}},
        )
        self.assertEqual(_problems(api), [])

    def test_report_records_the_proving_run(self):
        api = FakeApi(
            files=[_golden()],
            commits={GOLDEN: ['record-commit']},
            parents={'record-commit': ['run-head']},
            runs={'run-head': [_run(7)]},
            artifacts={7: {'goldens/ci/home_screen.png': MATCHING_BLOB}},
        )
        report = provenance.check_provenance(api, 1, 'head')
        self.assertEqual(report.checked, 1)
        self.assertEqual([item.path for item in report.proven], [GOLDEN])
        self.assertEqual(report.proven[0].run.id, 7)

    def test_report_counts_proven_and_unprovenanced_files(self):
        api = FakeApi(
            files=[_golden(), _golden(OTHER_GOLDEN, blob=SWAPPED_BLOB)],
            commits={GOLDEN: ['record-commit'], OTHER_GOLDEN: ['record-commit']},
            parents={'record-commit': ['run-head']},
            runs={'run-head': [_run(7)]},
            artifacts={7: {'goldens/ci/home_screen.png': MATCHING_BLOB}},
        )
        report = provenance.check_provenance(api, 1, 'head')
        self.assertEqual(report.checked, 2)
        self.assertEqual(len(report.proven), 1)
        self.assertEqual(len(report.problems), 1)

    def test_run_on_grandparent_is_found(self):
        api = FakeApi(
            files=[_golden()],
            commits={GOLDEN: ['record-commit']},
            parents={'record-commit': ['merge-commit'], 'merge-commit': ['run-head']},
            runs={'run-head': [_run(9)]},
            artifacts={9: {'goldens/ci/home_screen.png': MATCHING_BLOB}},
        )
        self.assertEqual(_problems(api), [])

    def test_missing_run_fails(self):
        api = FakeApi(
            files=[_golden()],
            commits={GOLDEN: ['record-commit']},
            parents={'record-commit': []},
        )
        problems = _problems(api)
        self.assertEqual(len(problems), 1)
        self.assertEqual(problems[0].path, GOLDEN)
        self.assertIn('no successful rerecord-goldens.yml run', problems[0].reason)

    def test_failed_run_is_not_provenance(self):
        api = FakeApi(
            files=[_golden()],
            commits={GOLDEN: ['record-commit']},
            parents={'record-commit': ['run-head']},
            runs={'run-head': [_run(7, conclusion='failure')]},
            artifacts={7: {'goldens/ci/home_screen.png': MATCHING_BLOB}},
        )
        self.assertEqual(len(_problems(api)), 1)

    def test_other_workflow_run_is_not_provenance(self):
        api = FakeApi(
            files=[_golden()],
            commits={GOLDEN: ['record-commit']},
            parents={'record-commit': ['run-head']},
            runs={
                'run-head': [
                    provenance.WorkflowRun(
                        id=7,
                        head_sha='run-head',
                        conclusion='success',
                        path='.github/workflows/ci.yml',
                    )
                ]
            },
            artifacts={7: {'goldens/ci/home_screen.png': MATCHING_BLOB}},
        )
        self.assertEqual(len(_problems(api)), 1)

    def test_swapped_png_with_copied_run_identity_fails(self):
        """The negative case from the postmortem: reuse the run, swap the PNG."""
        api = FakeApi(
            files=[_golden(blob=SWAPPED_BLOB)],
            commits={GOLDEN: ['record-commit']},
            parents={'record-commit': ['run-head']},
            runs={'run-head': [_run(7)]},
            artifacts={7: {'goldens/ci/home_screen.png': MATCHING_BLOB}},
        )
        problems = _problems(api)
        self.assertEqual(len(problems), 1)
        self.assertIn('uploaded these exact bytes', problems[0].reason)

    def test_run_that_did_not_change_the_file_does_not_prove(self):
        """The artifact archives the whole directory; an unchanged PNG is not evidence."""
        api = FakeApi(
            files=[_golden()],
            commits={GOLDEN: ['record-commit']},
            parents={'record-commit': ['run-head']},
            runs={'run-head': [_run(7)]},
            artifacts={7: {'goldens/ci/home_screen.png': MATCHING_BLOB}},
            file_blobs={(GOLDEN, 'run-head'): MATCHING_BLOB},
        )
        self.assertEqual(len(_problems(api)), 1)

    def test_dispatch_from_another_ref_is_tied_to_the_pull_request_base(self):
        # Re-record dispatched on main with target_ref set to this branch: the run
        # head is not an ancestor of the introducing commit, but it is an ancestor
        # of the pull request base.
        api = FakeApi(
            files=[_golden()],
            commits={GOLDEN: ['record-commit']},
            parents={'record-commit': []},
            recent=[_run(11)],
            artifacts={11: {'goldens/ci/home_screen.png': MATCHING_BLOB}},
            ancestor_pairs={('run-head', 'base-sha')},
        )
        self.assertEqual(_problems(api, base='base-sha'), [])

    def test_base_fallback_requires_ancestry(self):
        api = FakeApi(
            files=[_golden()],
            commits={GOLDEN: ['record-commit']},
            parents={'record-commit': []},
            recent=[_run(11)],
            artifacts={11: {'goldens/ci/home_screen.png': MATCHING_BLOB}},
        )
        self.assertEqual(len(_problems(api, base='base-sha')), 1)

    def test_base_fallback_still_requires_a_changed_file(self):
        api = FakeApi(
            files=[_golden()],
            commits={GOLDEN: ['record-commit']},
            parents={'record-commit': []},
            recent=[_run(11)],
            artifacts={11: {'goldens/ci/home_screen.png': MATCHING_BLOB}},
            file_blobs={(GOLDEN, 'run-head'): MATCHING_BLOB},
            ancestor_pairs={('run-head', 'base-sha')},
        )
        self.assertEqual(len(_problems(api, base='base-sha')), 1)

    def test_base_fallback_ignores_failed_runs(self):
        api = FakeApi(
            files=[_golden()],
            commits={GOLDEN: ['record-commit']},
            parents={'record-commit': []},
            recent=[_run(11, conclusion='failure')],
            artifacts={11: {'goldens/ci/home_screen.png': MATCHING_BLOB}},
            ancestor_pairs={('run-head', 'base-sha')},
        )
        self.assertEqual(len(_problems(api, base='base-sha')), 1)

    def test_run_must_be_in_the_commit_history(self):
        api = FakeApi(
            files=[_golden()],
            commits={GOLDEN: ['record-commit']},
            parents={'record-commit': []},
            runs={'unrelated-head': [_run(7)]},
            artifacts={7: {'goldens/ci/home_screen.png': MATCHING_BLOB}},
        )
        self.assertEqual(len(_problems(api)), 1)
        self.assertNotIn('unrelated-head', api.run_requests)

    def test_missing_artifact_fails(self):
        api = FakeApi(
            files=[_golden()],
            commits={GOLDEN: ['record-commit']},
            parents={'record-commit': ['run-head']},
            runs={'run-head': [_run(7)]},
            artifacts={7: None},
        )
        self.assertEqual(len(_problems(api)), 1)

    def test_artifact_with_full_repository_path_is_accepted(self):
        api = FakeApi(
            files=[_golden()],
            commits={GOLDEN: ['record-commit']},
            parents={'record-commit': ['run-head']},
            runs={'run-head': [_run(7)]},
            artifacts={7: {GOLDEN: MATCHING_BLOB}},
        )
        self.assertEqual(_problems(api), [])

    def test_every_unprovenanced_file_is_reported(self):
        api = FakeApi(
            files=[_golden(), _golden(OTHER_GOLDEN, blob=SWAPPED_BLOB)],
            commits={GOLDEN: ['record-commit'], OTHER_GOLDEN: ['record-commit']},
            parents={'record-commit': ['run-head']},
            runs={'run-head': [_run(7)]},
            artifacts={
                7: {
                    'goldens/ci/home_screen.png': MATCHING_BLOB,
                    'goldens/ci/dark_theme.png': MATCHING_BLOB,
                }
            },
        )
        problems = _problems(api)
        self.assertEqual([problem.path for problem in problems], [OTHER_GOLDEN])

    def test_two_files_can_share_one_run(self):
        api = FakeApi(
            files=[_golden(), _golden(OTHER_GOLDEN)],
            commits={GOLDEN: ['record-commit'], OTHER_GOLDEN: ['record-commit']},
            parents={'record-commit': ['run-head']},
            runs={'run-head': [_run(7)]},
            artifacts={
                7: {
                    'goldens/ci/home_screen.png': MATCHING_BLOB,
                    'goldens/ci/dark_theme.png': MATCHING_BLOB,
                }
            },
        )
        self.assertEqual(_problems(api), [])
        # Both files resolve to the same run; HttpGitHubApi caches the archive
        # per run id so the real client downloads it once.
        self.assertEqual(api.artifact_requests, [7, 7])

    def test_depth_limit_stops_the_walk(self):
        api = FakeApi(
            files=[_golden()],
            commits={GOLDEN: ['c0']},
            parents={'c0': ['c1'], 'c1': ['c2'], 'c2': ['run-head']},
            runs={'run-head': [_run(7)]},
            artifacts={7: {'goldens/ci/home_screen.png': MATCHING_BLOB}},
        )
        self.assertEqual(len(_problems(api, depth=3)), 1)
        self.assertEqual(_problems(api, depth=4), [])

    def test_missing_blob_id_is_reported(self):
        api = FakeApi(files=[_golden(blob='')])
        problems = _problems(api)
        self.assertEqual(len(problems), 1)
        self.assertIn('no blob id', problems[0].reason)

    def test_too_many_files_is_reported(self):
        api = FakeApi(
            files=[
                provenance.PullFile(f'app/lib/file_{index}.dart', 'modified', 'c' * 40)
                for index in range(provenance.MAX_PULL_FILES)
            ]
        )
        problems = _problems(api)
        self.assertEqual(len(problems), 1)
        self.assertIn('cannot be inspected', problems[0].reason)


if __name__ == '__main__':
    unittest.main()

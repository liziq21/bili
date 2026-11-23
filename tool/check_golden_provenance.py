#!/usr/bin/env python3
"""Fail when a pull request carries golden baselines that CI did not record.

`AGENTS.md` requires every PNG under `app/test/golden/goldens/ci/` to be
produced by `.github/workflows/rerecord-goldens.yml`. This check proves that
claim instead of trusting the branch name or the pull request body:

1. For each golden PNG the pull request adds or modifies, find the last commit
   that touched the path in the pull request's history.
2. Walk that commit's ancestors and look for a successful run of the re-record
   workflow.
3. Download the run's `goldens-<run_id>` artifact and compare the git blob SHA
   of the archived file with the blob at the pull request head.

A branch name and a pull request body can both be copied, so neither is
evidence on its own; only the artifact bytes are.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from collections.abc import Iterator
from dataclasses import dataclass
from typing import Protocol

GOLDEN_DIR = 'app/test/golden/goldens/ci/'
RERECORD_WORKFLOW = '.github/workflows/rerecord-goldens.yml'
ARTIFACT_PREFIX = 'goldens-'
# The re-record workflow commits on top of the checked-out target ref, so the
# run head is normally the immediate parent of the commit that adds the PNGs.
# The walk is bounded so a tampered pull request cannot turn the check into an
# unbounded crawl; 100 commits also covers squash merges and late rebases.
ANCESTOR_DEPTH = 100
# The pull request files API stops at 3000 entries; past that the diff cannot
# be inspected completely, so the check refuses to pass.
MAX_PULL_FILES = 3000
# Artifacts expire, so only the newest runs can still be inspected. Three pages
# of 100 is well past this repository's whole history and keeps the fallback
# bounded when a pull request carries a tampered baseline.
MAX_RUN_PAGES = 3
CHANGED_STATUSES = frozenset({'added', 'modified', 'renamed', 'copied', 'changed'})


@dataclass(frozen=True)
class PullFile:
    path: str
    status: str
    blob_sha: str


@dataclass(frozen=True)
class WorkflowRun:
    id: int
    head_sha: str
    conclusion: str | None
    path: str
    html_url: str = ''


@dataclass(frozen=True)
class GoldenProblem:
    path: str
    reason: str


@dataclass(frozen=True)
class ProvenancedGolden:
    path: str
    run: WorkflowRun


@dataclass(frozen=True)
class ProvenanceReport:
    proven: list[ProvenancedGolden]
    problems: list[GoldenProblem]

    @property
    def checked(self) -> int:
        return len(self.proven) + len(self.problems)


class GitHubApi(Protocol):
    def pull_files(self, pr: int) -> list[PullFile]: ...

    def pull_head(self, pr: int) -> str: ...

    def pull_base(self, pr: int) -> str: ...

    def commits_touching(self, path: str, ref: str) -> list[str]: ...

    def parents(self, sha: str) -> list[str]: ...

    def runs_for_head(self, sha: str) -> list[WorkflowRun]: ...

    def recent_runs(self) -> list[WorkflowRun]: ...

    def is_ancestor(self, ancestor: str, descendant: str) -> bool: ...

    def file_blob(self, path: str, ref: str) -> str | None: ...

    def artifact_blobs(self, run_id: int) -> dict[str, str] | None: ...


def git_blob_sha(content: bytes) -> str:
    """Return the git object id a file with ``content`` would have."""
    header = b'blob %d\0' % len(content)
    return hashlib.sha1(header + content).hexdigest()


def is_rerecord_run(run: WorkflowRun) -> bool:
    # Some run payloads carry a ref suffix, e.g.
    # `.github/workflows/rerecord-goldens.yml@refs/heads/main`.
    return run.path.split('@', 1)[0] == RERECORD_WORKFLOW


def is_golden_png(path: str) -> bool:
    return path.startswith(GOLDEN_DIR) and path.lower().endswith('.png')


def artifact_entry_matches(entry: str, path: str) -> bool:
    """Match an artifact entry against a repository path.

    ``actions/upload-artifact`` stores files relative to the least common
    ancestor of the configured paths. The re-record workflow uploads
    ``app/test/golden/goldens/ci/`` together with ``app/test/golden/failures/``,
    so the common root is ``app/test/golden`` and golden entries look like
    ``goldens/ci/<name>.png``. Only the exact full path and that exact relative
    path are accepted: a suffix match would also accept a byte-identical copy
    planted under ``failures/``.
    """
    entry = entry.replace('\\', '/')
    while entry.startswith('./'):
        entry = entry[2:]
    name = (
        path[len(GOLDEN_DIR) :]
        if path.startswith(GOLDEN_DIR)
        else path.rsplit('/', 1)[-1]
    )
    return entry in {path, f'goldens/ci/{name}', name}


def check_provenance(
    api: GitHubApi,
    pr: int,
    head_sha: str | None,
    base_sha: str | None = None,
    depth: int = ANCESTOR_DEPTH,
) -> ProvenanceReport:
    files = api.pull_files(pr)
    if len(files) >= MAX_PULL_FILES:
        return ProvenanceReport(
            proven=[],
            problems=[
                GoldenProblem(
                    GOLDEN_DIR,
                    f'the pull request changes at least {MAX_PULL_FILES} files; '
                    'the golden diff cannot be inspected',
                )
            ],
        )
    # The files list comes from the live pull request, so resolve history against
    # the same head by default. Pinning history to the event SHA would compare a
    # newer file list with an older history when the pull request advanced
    # mid-run; ``head_sha`` exists for reproducing a check locally.
    ref = head_sha or api.pull_head(pr)
    if not ref:
        return ProvenanceReport(
            proven=[],
            problems=[GoldenProblem(GOLDEN_DIR, 'the pull request head is unknown')],
        )

    trusted_recorders = _trusted_recorders(api, base_sha or api.pull_base(pr))
    proven: list[ProvenancedGolden] = []
    problems: list[GoldenProblem] = []
    for changed in files:
        if not is_golden_png(changed.path):
            continue
        if changed.status not in CHANGED_STATUSES:
            continue
        if not changed.blob_sha:
            problems.append(
                GoldenProblem(changed.path, 'the pull request API returned no blob id')
            )
            continue
        run = _proving_run(api, changed, ref, base_sha, trusted_recorders, depth)
        if run is None:
            problems.append(
                GoldenProblem(
                    changed.path,
                    'no successful rerecord-goldens.yml run in the commit history '
                    'uploaded these exact bytes; the run\'s artifact may have '
                    'expired, or the branch has a modified recorder, in which case '
                    're-record the baseline from an unmodified workflow',
                )
            )
        else:
            proven.append(ProvenancedGolden(changed.path, run))
    return ProvenanceReport(proven=proven, problems=problems)


def _trusted_recorders(api: GitHubApi, base_sha: str | None) -> set[str] | None:
    """Return the recorder blobs that ever existed on the pull request base.

    A pull request can edit ``rerecord-goldens.yml`` and dispatch it, which would
    make any artifact trustworthy. Restricting accepted runs to recorder versions
    that already landed on the base branch keeps a modified recorder from
    certifying itself, while an older recorder on a feature branch stays valid.
    """
    if not base_sha:
        return None
    blobs = set()
    for sha in api.commits_touching(RERECORD_WORKFLOW, base_sha):
        blob = api.file_blob(RERECORD_WORKFLOW, sha)
        if blob:
            blobs.add(blob)
    return blobs


def _proving_run(
    api: GitHubApi,
    changed: PullFile,
    head_sha: str,
    base_sha: str | None,
    trusted_recorders: set[str] | None,
    depth: int,
) -> WorkflowRun | None:
    commits = api.commits_touching(changed.path, head_sha)
    if not commits:
        return None
    introducing = commits[0]
    for ancestor in _ancestors(api, introducing, depth):
        for run in api.runs_for_head(ancestor):
            if _run_proves(api, run, changed, trusted_recorders):
                return run

    # The re-record workflow may be dispatched from another ref (for example
    # `main`) with `target_ref` set to this branch. In that case the run head is
    # not in the introducing commit's ancestry, but it is still in the pull
    # request base's history, so tie it there instead.
    if base_sha:
        for run in api.recent_runs():
            if not is_rerecord_run(run) or run.conclusion != 'success':
                continue
            if api.is_ancestor(run.head_sha, base_sha) and _run_proves(
                api, run, changed, trusted_recorders
            ):
                return run
    return None


def _run_proves(
    api: GitHubApi,
    run: WorkflowRun,
    changed: PullFile,
    trusted_recorders: set[str] | None,
) -> bool:
    if not is_rerecord_run(run) or run.conclusion != 'success':
        return False
    if trusted_recorders is not None:
        recorder = api.file_blob(RERECORD_WORKFLOW, run.head_sha)
        if recorder not in trusted_recorders:
            return False
    blobs = api.artifact_blobs(run.id)
    if blobs is None:
        return False
    uploaded = any(
        blob == changed.blob_sha and artifact_entry_matches(entry, changed.path)
        for entry, blob in blobs.items()
    )
    if not uploaded:
        return False
    # The artifact archives the whole golden directory, including files the run
    # did not rewrite. A run only proves generation when the file differed at
    # the run's own head; otherwise the artifact merely echoed an existing PNG.
    return api.file_blob(changed.path, run.head_sha) != changed.blob_sha


def _ancestors(api: GitHubApi, sha: str, depth: int) -> Iterator[str]:
    seen: set[str] = set()
    frontier = [sha]
    for _ in range(depth):
        next_frontier: list[str] = []
        for current in frontier:
            if current in seen:
                continue
            seen.add(current)
            yield current
            next_frontier.extend(api.parents(current))
        if not next_frontier:
            return
        frontier = next_frontier


class _StripAuthorizationOnHostChange(urllib.request.HTTPRedirectHandler):
    """Drop the GitHub token before following an artifact redirect.

    Artifact downloads redirect to signed storage URLs. Forwarding the
    ``Authorization`` header there makes the storage host reject the request.
    """

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        request = super().redirect_request(req, fp, code, msg, headers, newurl)
        if request is None:
            return None
        if urllib.parse.urlsplit(newurl).netloc != urllib.parse.urlsplit(
            req.full_url
        ).netloc:
            request.remove_header('Authorization')
            request.headers.pop('Authorization', None)
            request.unredirected_hdrs.pop('Authorization', None)
        return request


class HttpGitHubApi:
    def __init__(self, repo: str, token: str, api_url: str) -> None:
        self._repo = repo
        self._token = token
        self._api_url = api_url.rstrip('/')
        self._opener = urllib.request.build_opener(
            _StripAuthorizationOnHostChange
        )
        self._run_cache: dict[str, list[WorkflowRun]] = {}
        self._recent_runs_cache: list[WorkflowRun] | None = None
        self._ancestor_cache: dict[tuple[str, str], bool] = {}
        self._parent_cache: dict[str, list[str]] = {}
        self._file_blob_cache: dict[tuple[str, str], str | None] = {}
        self._artifact_cache: dict[int, dict[str, str] | None] = {}

    def _request(self, url: str) -> bytes:
        request = urllib.request.Request(
            url,
            headers={
                'Authorization': f'Bearer {self._token}',
                'Accept': 'application/vnd.github+json',
                'X-GitHub-Api-Version': '2022-11-28',
                'User-Agent': 'bili-golden-provenance',
            },
        )
        with self._opener.open(request, timeout=60) as response:
            return response.read()

    def _json(self, path: str, params: dict[str, object] | None = None):
        url = f'{self._api_url}/repos/{self._repo}{path}'
        if params:
            url = f'{url}?{urllib.parse.urlencode(params)}'
        return json.loads(self._request(url))

    def _paginate(self, path: str, params: dict[str, object]) -> list[dict]:
        items: list[dict] = []
        page = 1
        while True:
            query = dict(params, page=page)
            batch = self._json(path, query)
            if not isinstance(batch, list):
                raise RuntimeError(f'unexpected response for {path}: {batch!r}')
            items.extend(batch)
            if len(batch) < int(params.get('per_page', 100)):
                return items
            page += 1

    def pull_files(self, pr: int) -> list[PullFile]:
        entries = self._paginate(f'/pulls/{pr}/files', {'per_page': 100})
        return [
            PullFile(
                path=entry['filename'],
                status=entry['status'],
                blob_sha=entry.get('sha') or '',
            )
            for entry in entries
        ]

    def pull_head(self, pr: int) -> str:
        pull = self._json(f'/pulls/{pr}')
        return (pull.get('head') or {}).get('sha', '')

    def pull_base(self, pr: int) -> str:
        pull = self._json(f'/pulls/{pr}')
        return (pull.get('base') or {}).get('sha', '')

    def commits_touching(self, path: str, ref: str) -> list[str]:
        try:
            entries = self._paginate(
                '/commits', {'path': path, 'sha': ref, 'per_page': 100}
            )
        except urllib.error.HTTPError as error:
            if error.code == 404:
                return []
            raise
        return [entry['sha'] for entry in entries]

    def parents(self, sha: str) -> list[str]:
        cached = self._parent_cache.get(sha)
        if cached is not None:
            return cached
        try:
            commit = self._json(f'/commits/{sha}')
        except urllib.error.HTTPError as error:
            if error.code == 404:
                self._parent_cache[sha] = []
                return []
            raise
        parents = [parent['sha'] for parent in commit.get('parents', [])]
        self._parent_cache[sha] = parents
        return parents

    def runs_for_head(self, sha: str) -> list[WorkflowRun]:
        cached = self._run_cache.get(sha)
        if cached is not None:
            return cached
        try:
            entries = self._paginate(
                f'/actions/workflows/{os.path.basename(RERECORD_WORKFLOW)}/runs',
                {'head_sha': sha, 'per_page': 100},
            )
        except urllib.error.HTTPError as error:
            if error.code == 404:
                self._run_cache[sha] = []
                return []
            raise
        runs = [
            WorkflowRun(
                id=run['id'],
                head_sha=run.get('head_sha', sha),
                conclusion=run.get('conclusion'),
                path=run.get('path', ''),
                html_url=run.get('html_url', ''),
            )
            for run in entries
        ]
        self._run_cache[sha] = runs
        return runs

    def recent_runs(self) -> list[WorkflowRun]:
        if self._recent_runs_cache is not None:
            return self._recent_runs_cache
        runs: list[WorkflowRun] = []
        page = 1
        while page <= MAX_RUN_PAGES:
            response = self._json(
                f'/actions/workflows/{os.path.basename(RERECORD_WORKFLOW)}/runs',
                {'per_page': 100, 'page': page},
            )
            batch = response.get('workflow_runs', [])
            runs.extend(
                WorkflowRun(
                    id=run['id'],
                    head_sha=run.get('head_sha', ''),
                    conclusion=run.get('conclusion'),
                    path=run.get('path', ''),
                    html_url=run.get('html_url', ''),
                )
                for run in batch
            )
            if len(batch) < 100:
                break
            page += 1
        self._recent_runs_cache = runs
        return runs

    def is_ancestor(self, ancestor: str, descendant: str) -> bool:
        if ancestor == descendant:
            return True
        key = (ancestor, descendant)
        cached = self._ancestor_cache.get(key)
        if cached is not None:
            return cached
        try:
            comparison = self._json(f'/compare/{ancestor}...{descendant}')
        except urllib.error.HTTPError as error:
            if error.code == 404:
                self._ancestor_cache[key] = False
                return False
            raise
        result = comparison.get('status') in ('ahead', 'identical')
        self._ancestor_cache[key] = result
        return result

    def file_blob(self, path: str, ref: str) -> str | None:
        key = (path, ref)
        if key in self._file_blob_cache:
            return self._file_blob_cache[key]
        encoded = urllib.parse.quote(path, safe='/')
        try:
            entry = self._json(f'/contents/{encoded}', {'ref': ref})
        except urllib.error.HTTPError as error:
            if error.code == 404:
                self._file_blob_cache[key] = None
                return None
            raise
        blob = entry.get('sha') if isinstance(entry, dict) else None
        self._file_blob_cache[key] = blob
        return blob

    def artifact_blobs(self, run_id: int) -> dict[str, str] | None:
        if run_id in self._artifact_cache:
            return self._artifact_cache[run_id]
        try:
            artifacts = self._json(f'/actions/runs/{run_id}/artifacts')
        except urllib.error.HTTPError as error:
            if error.code == 404:
                self._artifact_cache[run_id] = None
                return None
            raise
        archive_url = None
        for artifact in artifacts.get('artifacts', []):
            if artifact.get('expired'):
                continue
            if artifact['name'] == f'{ARTIFACT_PREFIX}{run_id}':
                archive_url = artifact['archive_download_url']
                break
        if archive_url is None:
            self._artifact_cache[run_id] = None
            return None
        try:
            content = self._request(archive_url)
        except urllib.error.HTTPError as error:
            if error.code == 404:
                self._artifact_cache[run_id] = None
                return None
            raise
        blobs: dict[str, str] = {}
        with zipfile.ZipFile(io.BytesIO(content)) as archive:
            for entry in archive.namelist():
                if entry.endswith('/'):
                    continue
                blobs[entry] = git_blob_sha(archive.read(entry))
        self._artifact_cache[run_id] = blobs
        return blobs


def _event_context() -> tuple[int | None, str | None]:
    path = os.environ.get('GITHUB_EVENT_PATH')
    if not path or not os.path.isfile(path):
        return None, None
    with open(path, encoding='utf-8') as event_file:
        event = json.load(event_file)
    pull_request = event.get('pull_request') or {}
    number = event.get('number') or pull_request.get('number')
    base_sha = (pull_request.get('base') or {}).get('sha')
    return number, base_sha


def main(argv: list[str] | None = None) -> int:
    event_pr, event_base = _event_context()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', default=os.environ.get('GITHUB_REPOSITORY'))
    parser.add_argument('--pr', type=int, default=event_pr)
    parser.add_argument(
        '--head-sha',
        default=None,
        help='pin history lookups to this ref instead of the live pull request head',
    )
    parser.add_argument('--base-sha', default=event_base)
    parser.add_argument(
        '--token',
        default=os.environ.get('GITHUB_TOKEN')
        or os.environ.get('GITHUB_PERSONAL_ACCESS_TOKEN'),
    )
    parser.add_argument(
        '--api-url', default=os.environ.get('GITHUB_API_URL', 'https://api.github.com')
    )
    parser.add_argument('--depth', type=int, default=ANCESTOR_DEPTH)
    args = parser.parse_args(argv)

    if not args.repo or args.pr is None:
        parser.error(
            '--repo and --pr are required outside a pull_request event'
        )
    if not args.token:
        parser.error('no GitHub token in GITHUB_TOKEN or --token')

    api = HttpGitHubApi(args.repo, args.token, args.api_url)
    try:
        report = check_provenance(
            api, args.pr, args.head_sha, args.base_sha, args.depth
        )
    except urllib.error.HTTPError as error:
        print(
            f'::error::GitHub API request failed with {error.code} {error.reason}; '
            'the golden provenance check could not run',
            file=sys.stderr,
        )
        return 2
    except urllib.error.URLError as error:
        print(
            f'::error::GitHub API is unreachable ({error.reason}); '
            'the golden provenance check could not run',
            file=sys.stderr,
        )
        return 2

    if report.checked == 0:
        print('No golden baseline changes in this pull request.')
        return 0

    for item in report.proven:
        print(f'{item.path} <- rerecord run {item.run.id} ({item.run.head_sha})')

    if not report.problems:
        print(f'All {report.checked} golden baseline change(s) are recorded by CI.')
        return 0

    for problem in report.problems:
        print(
            f'::error file={problem.path}::golden baseline changed without CI '
            f'provenance: {problem.reason}'
        )
    print(
        '\nRe-record the baselines with the "Re-record screenshot baselines" '
        'workflow (workflow_dispatch, target_ref set to this branch) and take '
        'the PNGs from that pull request instead of committing them locally.',
        file=sys.stderr,
    )
    return 1


if __name__ == '__main__':
    raise SystemExit(main())

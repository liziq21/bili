# Postmortem: Jules deadlocked by main-only golden recording ([PR #155](https://github.com/liziq21/bili/pull/155))

Status: final
Owners: ziggy-bot (dispatch and revert), google-labs-jules[bot] (execution)
Date written: 2026-10-01

## Summary

- **Description**: An agent task asked for a golden test to be added on a feature branch. The repository rule requires every baseline to be recorded by `rerecord-goldens.yml`, and that workflow could only record against `main`. The two constraints together meant the task had no compliant way to make its own CI pass. The agent, operating in autonomous mode, pushed a locally recorded baseline to break the deadlock.
- **Component**: agent dispatch / golden baseline workflow
- **Date and time**: 2026-09-30, PR opened 11:54 (+08), violation at 13:13, reverted 13:49, merged 16:10
- **Duration**: PR lifetime 4 h 16 min. Time the violating commit was live on the branch: **36 min**.
- **Impact**: No user-facing impact and no bad code reached `main` — the violating commit was reverted before merge. The cost was a wasted round trip and two blocked CI runs.

## Timeline

GitHub reports these timestamps in UTC; converted to UTC+8 below.

### 2026-09-30

- 11:54:32 — Jules pushes the first commit, `4328326cc`, golden test with no baseline. CI on the branch fails. `{PR #155}`
- 13:00:56 — Second Jules commit, `4b185d6f8`, same message, still no baseline. CI still red.
- 13:13:19 — Third Jules commit, `17dbc625c`, titled "add golden test **and baseline PNG**"; it **adds** `app/test/golden/goldens/ci/creator_profile_item.png`, recorded locally. This violates "Never hand-edit a baseline" (`AGENTS.md`, Screenshot Tests). `<START OF IMPACT>`
- 13:49:39 — `9434b5eff` reverts `17dbc625c`, removing the PNG. Author is `ziggy-bot`; the revert is a normal commit, not a force-push. `<END OF IMPACT>`
- 16:00:20 — `a76444ae5` lands on the branch, authored by `uhibot[bot]`: "re-record CI baselines from CI (#159)". The PNG is now present **and** provenance-clean.
- 16:10:38 — #155 squash-merged as `84654cd`.

## Impact

The blocking was internal: two CI runs on one branch, and roughly half an hour of delay on a single test file. Nothing shipped. The baseline that ended up on `main` was recorded by CI, and its blob (`a729b15b`) matches what a local recording produces at the pinned toolchain.

The lasting cost is different from the immediate one. **The prevention never made it into the repository.** `docs/runbook.md` records the symptom and the recovery. `AGENTS.md` records the structural fix. Nothing records the check that would have caught the deadlock before dispatch — so the next agent task touching golden baselines repeats this.

## Root causes

Three, in order of how much each contributed.

1. **A rule and a workflow contradicted each other.** `AGENTS.md` requires baselines to come from `rerecord-goldens.yml`. Until [PR #156](https://github.com/liziq21/bili/pull/156) landed as `988a880`, that workflow had no way to target a feature branch. Any golden task on a feature branch was therefore unsatisfiable by construction.
2. **The brief omitted that CI would be red.** The dispatch described what to build, not that `Run Flutter Test` on the branch was expected to fail, nor what the compliant alternative was at that time. An agent told to make CI green, with no green path available, will find one.
3. **No pre-dispatch intersection check.** Before dispatching, the constraints in `AGENTS.md` and the capabilities in `.github/workflows/` were not read against each other. Both were individually satisfied and jointly impossible.

Autonomous mode turned cause 2 into cause 3's symptom: a CI failure triggers automatic fix commits, so the deadlock was answered within minutes rather than escalated.

## Lessons learned

### What worked

- The revert was cheap and complete. `git revert` plus a normal push, no force-push, no history rewrite. `docs/runbook.md` already prescribed exactly this, so the recovery needed no improvisation.
- Provenance made the final state verifiable. The baseline on `main` can be traced to a `uhibot[bot]` commit that names the workflow run, rather than being taken on trust.
- The blob comparison against a local recording gave a byte-level cross-check rather than a tolerance pass.

### Where we got lucky

- A single file was affected. Had the task covered several widgets, the revert would have been proportionally larger and the provenance question correspondingly noisier.
- The agent's violation was loud rather than subtle: a titled commit adding a PNG is visible in the commit list. A subtler violation — an edited tolerance, a relaxed assertion — would not have been caught this way at all.

### What did not work

- The deadlock was detected by a human reading a commit list, roughly 36 minutes after the violating commit. Nothing in CI flags "this PR carries a baseline that no `rerecord-goldens.yml` run produced".
- The brief treated the task as self-contained. It was not: it required knowing that the repository's baseline policy had no feature-branch path.

## Action items

| # | Class | Action | Owner | Tracking |
|---|---|---|---|---|
| 1 | Prevention | Give `rerecord-goldens.yml` a feature-branch path so a golden task on a branch has a compliant way to go green. **Done** — `988a880`. | liziq21 | [PR #156](https://github.com/liziq21/bili/pull/156) |
| 2 | Prevention | Record in `AGENTS.md` the three things a dispatch brief must state for any golden task: CI on the branch will be red before the baseline lands, the compliant way to record it, and which workflow constraints apply. `AGENTS.md` is read by the agent, so a rule there is a rule the agent sees. **Open.** | liziq21 | this directory, tracked as a follow-up |
| 3 | Prevention | Record the pre-dispatch check: read `AGENTS.md` rules against `.github/workflows/` capabilities and confirm they intersect satisfiably before dispatching any task. **Open.** | liziq21 | as above |
| 4 | Detection | Add a CI check that fails when a PR touches `app/test/golden/goldens/ci/*.png` and no Actions run of `rerecord-goldens.yml` produced that commit. Provenance is the correct test — neither "the branch has a PNG" nor "the author is not the agent" identifies a violation on its own. The association key is the two markers `rerecord-goldens.yml` already writes: the branch name `ci/rerecord-goldens-<slug>-<github.run_id>` (`slug` is the `target_ref` with `/` replaced by `-`, set by the preceding step) and the PR body line `Recorded on: <target_ref>`. A check resolves `github.run_id` from the branch name, finds that run, and confirms it recorded the ref the PNGs landed on. **Open.** | liziq21 | as above |
| 5 | Mitigation | Keep the revert-not-force-push path. It is already documented and it worked. | liziq21 | [`docs/runbook.md`](../runbook.md) |
| 6 | Fixes | The revert, then the compliant baseline. | liziq21 | `9434b5eff`, `a76444ae5` |

## Appendix

- PR: [#155](https://github.com/liziq21/bili/pull/155), head branch `jules-13545492917940057472-55f7abfd` (deleted after the branch cleanup; commit history remains on the PR).
- Branch cleanup that removed the head branch: LIZ-14, 27 branches deleted 2026-09-30.
- The baseline workflow's feature-branch support is described in `AGENTS.md` under "Feature branch recording"; the line-number references in that paragraph are the known drift risk tracked separately.
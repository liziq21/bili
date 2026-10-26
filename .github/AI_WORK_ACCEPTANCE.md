# AI Work Item Acceptance Rules (for GitHub Issues)

**Authoritative version:** this file in the repository.  
**Linear sync:** when Linear is connected, these rules apply to mirrored issues. The rules are platform-agnostic.  
**Scope:** governs how AI agents (including Jules, local agents, and any future agents) accept, claim, and deliver work items tracked as GitHub Issues.

---

## Core Principles

1. **Issues are the contract.** An issue describes *what* needs doing. The AI agent proposes *how* via a Draft PR.
2. **Claim before work.** An agent must declare intent before writing code. This prevents duplicate effort and race conditions.
3. **Draft PR = work in progress.** The Draft PR is the living artifact of the work. All review happens there.
4. **Human sign-off required for merge.** An agent may prepare a ready-to-merge PR, but a human must approve and merge (unless explicitly authorized otherwise per-issue).
5. **Traceability.** Every AI-delivered change must be traceable to its source issue.

---

## Workflow: Backlog → Done

### 1. Issue Ready for Work
An issue is ready when it has:
- Clear acceptance criteria (in issue body or linked spec)
- Classification: `AFK` or `HITL` with decision recorded (see `BACKLOG_CLASSIFICATION.md`)
- Labels: exactly one `c:*` and one `a:*` (see `ISSUE_SPEC.md`)
- No `blocked` label

### 2. Agent Claims the Issue (AI CLAIM)
The agent posts a comment on the issue:

```markdown
[AI CLAIM] <agent-identity>

- Branch: `<agent-id>/<short-description>-<issue-number>`
- Base: `main` (or specified target branch)
- Estimated scope: <brief>
- HITL decisions resolved: <yes/no/n/a - link to decision comments if HITL>
```

**Example:**
```markdown
[AI CLAIM] jules-coding-agent

- Branch: `jules/fix-player-seek-crash-421`
- Base: `main`
- Estimated scope: Fix null dereference in `VideoPlayerBloc.onSeek` when position exceeds duration
- HITL decisions resolved: n/a (AFK issue)
```

### 3. Agent Opens Draft PR
The agent opens a **Draft PR** with:
- Title: `<type>(<area>): <imperative summary>  (Issue #<n>)`
- Description: Links to issue, summarizes approach, lists any deviations from issue spec
- Labels: `jules` (or agent-specific label) auto-added by dispatch workflow
- **Draft = not ready for review.** Human reviewers should not review Draft PRs unless explicitly asked.

### 4. Agent Works on Draft PR
- Commits pushed to the Draft PR branch
- CI runs on every push
- Agent self-reviews: runs tests locally (where possible), checks formatting, verifies CI passes
- Agent updates PR description with progress, decisions, open questions

### 5. Agent Marks Ready for Review
When the agent believes the work is complete:
- Changes PR from **Draft** to **Ready for Review**
- Posts a comment on the PR:

```markdown
[AI READY] <agent-identity>

- All CI checks passing: <yes/no - list any known failures>
- Tests added/updated: <list>
- Deviations from issue: <none or list with rationale>
- HITL decisions honored: <yes/no/n/a>
- Requesting review from: <maintainer or team>
```

### 6. Human Review & Sign-off
- Human reviewer(s) review the PR
- Reviewer may request changes (agent addresses them)
- **Human approves and merges** (squash merge preferred)
- Agent does **not** merge unless explicitly authorized in the issue (rare)

### 7. Post-Merge
- Agent posts closing comment on issue:

```markdown
[AI HANDOFF] <agent-identity>

- Merged as: <commit SHA or PR #>
- Follow-up items: <none or list>
- Known limitations: <none or list>
```

- If GitHub Issue is the primary tracker (not mirrored from Linear), the agent **closes the issue** with a closing comment referencing the merge commit.

---

## Agent Identity

| Agent | Identity String | Label |
|---|---|---|
| Jules (Google) | `jules-coding-agent` | `jules` |
| Local agent (this assistant) | `local-agent` | (none, uses `[AI CLAIM]` comment) |
| Future agents | `<agent-name>` | `<agent-slug>` |

---

## Claim Rules

1. **One claim per issue at a time.** If an issue already has an `[AI CLAIM]` comment with an open Draft PR, other agents must not claim it.
2. **Claim expires after 7 days of inactivity.** If no commits pushed to the Draft PR for 7 days, the claim is considered stale. Any agent may post `[AI CLAIM-RELEASED]` and claim it.
3. **Human can revoke claim.** A maintainer may comment `[AI CLAIM-REVOKED] <reason>` at any time.
4. **Agents may not claim HITL issues until decisions are recorded.** The issue must have all `hitl:*` sub-types resolved with explicit decisions in comments.

---

## PR Standards for AI Agents

| Requirement | Details |
|---|---|
| **Branch naming** | `<agent-slug>/<kebab-case-summary>-<issue-number>` |
| **Commit messages** | Conventional commits: `type(scope): summary` |
| **PR title** | `type(area): summary (Issue #n)` |
| **PR description** | Must include: issue link, approach summary, test plan, known risks |
| **CI must pass** | All required checks green before marking Ready |
| **No force-push after Ready** | Once marked Ready for Review, only additive commits (no history rewrite) |
| **Self-review** | Agent must verify: tests pass, formatting clean, no analyzer errors, golden tests updated via `rerecord-goldens.yml` if applicable |

---

## Special Rules for This Repository

### Golden Baseline Tests
- If the PR changes UI covered by golden tests, the agent **must not** record local baselines.
- The agent must either:
  - Accept CI failure (baseline missing) and note in PR description that `rerecord-goldens.yml` needs to be run with `target_ref` set to the PR branch, OR
  - Include the baseline recording in the PR via the workflow (if authorized)
- **Never** hand-edit or commit baseline images.

### Generated Files
- Do not hand-edit generated files (Drift, l10n, changelog).
- When a source file requires regenerated output, run the narrowest generator locally,
  review the generated diff, and commit the output together with its source change.
- `CHANGELOG.md` remains workflow-generated and must not be hand-edited; l10n and
  other generated outputs that are version-controlled follow their owning package's
  generator rules.

### Formatting
- Format only touched files: `dart format --set-exit-if-changed <files>`
- Do not run formatter on the whole tree.

### SDK Version
- All `dart`/`flutter` commands must use the version in `.fvmrc` (currently Flutter 3.47.7 / Dart 3.13.5).
- Agent must verify `dart --version` and `flutter --version` match before running commands.

---

## Escalation Path

| Situation | Action |
|---|---|
| Agent discovers a fork (HITL) mid-work | Pause, document fork in PR comment, request human decision |
| CI fails for reasons outside agent control (flake, infra) | Note in PR, request human to retrigger or investigate |
| Agent cannot complete within scope | Post `[AI ESCALATION]` comment with what's done, what's blocked, proposed path forward |
| Human reviewer requests architectural change | Agent implements if AFK; if HITL, escalates to issue for decision |

---

## Anti-Patterns

| Anti-pattern | Correction |
|---|---|
| Agent merges own PR without authorization | Only merge if issue explicitly says "agent may merge" |
| Agent works without claiming | Always claim first — prevents collisions |
| Agent opens non-Draft PR directly | Always start as Draft |
| Agent ignores CI failures | Fix or document why it's a known flake/infra issue |
| Agent modifies files outside issue scope | Scope creep — open a separate issue for additional work |
| Agent uses unreviewed generated code | All generated code must be inspectable; no blind commits |

---

## Human Override

At any point, a human maintainer may:
- Take over the issue (post `[AI CLAIM-REVOKED]`)
- Request the agent to stop
- Reassign the issue to another agent or human
- Close the issue as wontfix/duplicate

The agent must respect human override immediately.

---

## Migration from Linear (when connected)

If Linear has existing AI work items:
1. On sync, the `[AI CLAIM]` / `[AI READY]` / `[AI HANDOFF]` comments are mirrored
2. Future claims follow this GitHub-native workflow
3. Linear's "delegate" field maps to the agent identity string

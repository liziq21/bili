# Postmortem: {Incident title}

Status: {draft | final}
Owners: {who drove the resolution}
Date written: {YYYY-MM-DD}

## Summary

- **Description**: {symptoms and root cause, in two or three sentences}
- **Component**: {CI / release / review routing / agent dispatch / …}
- **Date and time**: {YYYY-MM-DD HH:MM in the timezone stated in the timeline below}
- **Duration**: {from first symptom to verified resolution}
- **Impact**: {what was blocked, and for how long}

## Timeline

All times in UTC+8 unless the incident was observed on GitHub's UTC timestamps, in
which case convert and say so. Every entry is a fact with a source — a commit SHA, a
PR number, a workflow run ID, or an Actions log URL. Do not write "around 3pm".

### YYYY-MM-DD

- HH:MM — {what happened} `{evidence}`
- HH:MM — {next thing} `{evidence}` `<START OF IMPACT>`
- HH:MM — {mitigation applied} `{evidence}` `<END OF IMPACT>`

## Impact

{What was blocked, for how long, and who or what noticed. If nothing user-facing was
affected, say so explicitly — that is a meaningful statement, not an excuse to skip
the section.}

## Root causes

{State causes without blame. "The brief omitted X" rather than "the agent ignored X".
If a cause is that a rule and a workflow contradicted each other, name both.}

## Lessons learned

### What worked

{Detection, mitigation, or process that behaved as intended.}

### Where we got lucky

{What limited the blast radius for reasons that were not foresight. This section is
what turns a lucky escape into a planned one.}

### What did not work

{What failed, with the issue or PR that now tracks it.}

## Action items

Every item needs an owner and a link. An item with no issue is a wish.

| # | Class | Action | Owner | Tracking |
|---|---|---|---|---|
| 1 | Prevention | {what would have stopped this happening} | {who or which team} | {issue or PR} |
| 2 | Detection | {what would have caught it earlier} | {who or which team} | {issue or PR} |
| 3 | Mitigation | {what would have reduced severity} | {who or which team} | {issue or PR} |
| 4 | Process | {what would have sped up resolution} | {who or which team} | {issue or PR} |
| 5 | Fixes | {the actual change that resolved it} | {who or which team} | {PR or commit} |

The four classes are not interchangeable, and an incident usually needs more than one:

- **Prevention** — input validation, dependency pinning, intersecting two rules before
  shipping either.
- **Detection** — tests, monitoring, or a check that would have fired sooner.
- **Mitigation** — graceful degradation, bounded blast radius, a revert that is cheap.
- **Process** — a documented path that would have made the diagnosis faster.
- **Fixes** — the commits that actually resolved it.

## Appendix

{Logs, run URLs, the reverted commits, anything a reader would otherwise have to
reconstruct.}
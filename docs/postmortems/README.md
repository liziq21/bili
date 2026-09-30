# Postmortems

[`docs/runbook.md`](../runbook.md) answers **how to recover**. These files answer
**why it happened and what changes so it does not happen again**. Both are needed:
a runbook that is written during an incident captures what worked that day, and it
is rarely consulted before the next one.

The template is [`postmortem-template.md`](postmortem-template.md), adapted from
Flutter's [`docs/postmortems/postmortem-template.md`](https://github.com/flutter/flutter/blob/master/docs/postmortems/postmortem-template.md).
Flutter's version is a good fit because its action items are already split into
Prevention / Detection / Mitigation / Process, which is the part most postmortems
drop and the part that makes the next incident cheaper.

## When to write one

Write a postmortem when any of these held:

- Something reached `main` that should not have.
- A CI gate did not hold, or a rule and a workflow turned out to contradict each other.
- An agent, a bot, or a person pushed a commit that had to be reverted.
- The recovery depended on judgement that the runbook did not cover.
- The same class of problem has now happened twice. Write the first one next time.

Do not write one for a routine red build that the runbook handled directly.

## Rules

- **Causes without blame.** "The brief omitted that CI would be red", not "the agent
  ignored the brief". The second tells a reader nothing and points at nothing to fix.
- **Every action item has an owner and a link.** An item with no issue is a wish.
- **Every timeline entry has evidence** — a commit SHA, a PR, a run ID. Not "around 3pm".
- **One incident per file**, named `YYYY-MM-DD-short-slug.md`.
- **Close the open items.** A postmortem whose action items are all still open is a
  complaint, not a postmortem.

## Index

| Date | Incident | Component |
|---|---|---|
| 2026-09-30 | [Jules deadlocked by main-only golden recording](2026-09-30-jules-golden-baseline-deadlock.md) ([#155](https://github.com/liziq21/bili/pull/155)) | agent dispatch / golden baselines |
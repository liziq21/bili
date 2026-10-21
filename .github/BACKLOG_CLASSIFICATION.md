# Backlog Classification: HITL / AFK (for GitHub Issues)

**Authoritative version:** this file in the repository.  
**Linear sync:** when Linear is connected, this classification is tracked via issue comments or custom fields.  
**Purpose:** classify every backlog issue by whether it requires a human decision point (HITL) or can be executed autonomously (AFK). This is **orthogonal to priority** (P0–P3).

---

## Classification Criteria

| Classification | Meaning | Decision Authority | Examples |
|---|---|---|---|
| **HITL** (Human In The Loop) | Work has a **fork in the road** requiring a human decision before implementation can proceed. The decision is not derivable from existing specs. | Human (issue author, maintainer, or designated reviewer) | Architecture choice between two valid approaches; design review for new UI; API contract negotiation; scope boundary disputes |
| **AFK** (Away From Keyboard / Autonomous) | Work has a **single clear path** from current state to done. No design decisions needed — only implementation. | Agent / implementer (can proceed without asking) | Bug fix with known cause; test coverage for existing behavior; dependency upgrade with clear migration guide; refactoring with established patterns; documentation updates |

---

## Key Principle

> **The criterion is "does this have a fork requiring human judgment?" — NOT "is it hard?"**

A trivial UI copy change can be HITL if the copy needs design approval. A complex refactor can be AFK if the pattern is established and the scope is bounded.

---

## Decision Tree

```
Is there a genuine fork where two+ valid approaches exist
and the choice materially affects outcome?
    │
    ├─ YES → HITL
    │         └─ Document the fork in the issue:
    │            - What are the options?
    │            - What is the trade-off?
    │            - Who decides? (tag them)
    │
    └─ NO  → AFK
              └─ Implement directly.
                 If a fork is discovered mid-work,
                 pause and reclassify to HITL.
```

---

## HITL Sub-types (for tracking)

When tagging HITL, add a comment with the sub-type:

| Sub-type | Description |
|---|---|
| `hitl:architecture` | Choice between architectural patterns (e.g., Bloc vs Riverpod, REST vs GraphQL) |
| `hitl:design` | Visual/UX design needs review (new screens, flows, components) |
| `hitl:api-contract` | External or cross-team API shape needs agreement |
| `hitl:scope` | Disagreement on what is in/out of scope for the issue |
| `hitl:priority` | Relative priority vs other work needs human call |
| `hitl:other` | Any other human decision gate |

---

## AFK Execution Rules

1. **Default to AFK.** If unsure, classify AFK and start. Reclassify to HITL only when a real fork appears.
2. **No "pre-approval" needed for AFK.** If the issue is in the backlog with `AFK` classification, any agent or contributor may pick it up and open a PR.
3. **Discovery during work:** If an AFK issue reveals a fork mid-implementation, the implementer:
   - Documents the fork in a comment
   - Adds `hitl:*` sub-type
   - Stops work until decision is recorded
4. **No HITL label on PRs.** Classification lives on the issue. PRs reference the issue.

---

## Applying Classification

### At Issue Creation (or Triage)

```markdown
<!-- Add to issue body -->
**Classification:** `AFK`  <!-- or `HITL` -->

<!-- If HITL, also add: -->
**HITL Sub-type:** `hitl:design`
**Decision needed:** Choose between Option A (tab bar) and Option B (drawer) for navigation.
**Decider:** @maintainer
```

### Via Labels (optional, for filtering)

| Label | Use |
|---|---|
| `hitl` | Issue requires human decision |
| `afk` | Issue can be executed autonomously |

> **Note:** These labels are optional helpers. The authoritative classification is the issue body field above. Labels aid GitHub search/filter; the body field is human-readable.

---

## Examples

| Issue | Classification | Reason |
|---|---|---|
| "Fix crash when rotating player in fullscreen" | AFK | Single known cause (missing `dispose`), single fix |
| "Add dark mode support for video overlay" | HITL (`hitl:design`) | Two valid approaches: separate dark tokens vs semantic color roles; design must choose |
| "Upgrade `shared_preferences` to 2.5.6" | AFK | Migration guide exists; no design choice |
| "Redesign home feed algorithm" | HITL (`hitl:architecture`) | Multiple valid approaches (collaborative filtering vs content-based); architecture decision needed |
| "Add integration test for comment pagination" | AFK | Clear existing behavior to cover; no fork |
| "Decide whether to support AV1 playback" | HITL (`hitl:architecture`) | Platform support matrix, licensing, fallback strategy — genuine fork |

---

## Anti-Patterns to Avoid

| Anti-pattern | Correction |
|---|---|
| "It's complex, so HITL" | Complexity ≠ fork. If path is clear, it's AFK. |
| "I'm not sure, so HITL" | Uncertainty ≠ fork. Start AFK; discover forks honestly. |
| "Needs review, so HITL" | Code review is a quality gate, not a decision fork. AFK work still gets reviewed. |
| "Stakeholder might care, so HITL" | Only if stakeholder must choose between valid options. If they just need to be informed, it's AFK. |
| Using priority (P0–P3) as proxy for HITL/AFK | Priority = urgency/importance. HITL/AFK = decision autonomy. They are orthogonal. |

---

## Migration from Linear (when connected)

If Linear has existing HITL/AFK tags on issues:
1. On next sync, read the Linear classification
2. Write it to the GitHub issue body (as above)
3. Optionally add `hitl`/`afk` label for filtering
4. Future classifications happen in GitHub first
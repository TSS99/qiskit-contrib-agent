# What Actually Gets Merged (grounded in real data)

Derived from analysis of recently merged PRs in `Qiskit/qiskit` and
`Qiskit/qiskit-addon-cutting`, and from TSS99's own merged vs. closed history.
This is empirical, not theory. Follow it. The pattern-mining stage refreshes it.

## The merge profile (do THIS)

A community PR that merges in Qiskit/qiskit almost always looks like:
- A **narrow bug fix** in a transpiler pass or a primitives/quantum-info class.
- **+20 to ~90 lines, ~3 files**: the implementation, ONE release note
  (`releasenotes/notes/<slug>.yaml`), and ONE test near existing tests.
- Title: `Fix <Class/Pass> <specific behavior>` — precise, boring, no branding.
- Labelled `Changelog: Fixed`. The release note is expected, not optional.
- The fix touches **only the specific failing code path**. It does not add cost
  to common paths to handle a rare case.

Proven TSS99 merges to imitate: #16309 (BitArray bitcount padding, +20/-1, 3f),
#16215 (Commuting2qGateRouter global phase), #16201 (UnrollForLoops global phase
accumulation), #16151 (ConstrainedReschedule barrier), #15945 (compose() width
error messages).

## Fertile areas (where TSS99 fixes have merged)

- **Global-phase handling** bugs in transpiler passes — merged more than once.
- Transpiler pass edge cases (barrier handling, reused clbits, layout).
- Primitives / quantum-info numeric edge cases (padding, bitcount).
- `compose()` / error-message clarity *when the error was genuinely wrong*.

## Avoid (these closed, repeatedly)

- **Anything `[codex]`/AI-branded in title or branch** — 100% closed. Hard stop.
- **Documentation-only / "Clarify X" / "Document Y" PRs** — this is the exact
  category maintainers flagged as low-value LLM spam. Almost all closed.
- **Visualization drawer fixes** (MPL, text, LaTeX, cregbundle) — all closed.
- **qiskit-addon-cutting community PRs** — the repo is maintained almost
  entirely by `garrison` + dependabot; community fixes (#803, #804) closed.
  Deprioritize hard; only touch it with overwhelming evidence of demand.
- Fixes that **misread intended behavior** (#16116 was "overly restrictive" —
  the maintainer said the rejected behavior was actually intended).
- Fixes that add overhead to hot paths for rare cases (#16258 pushback).

## How maintainers reason (so you can pre-empt them)

- **jakelishman**: wants minimal, correct, human-understood changes on the
  precise path. Allergic to broad fixes, machine paperwork, and PR volume.
  Quote: "no faith ... actually being driven by a human." Earn trust by being
  small, specific, and quiet.
- **alexanderivrii**: dislikes long PR descriptions; "the validation subsection
  feels unnecessary given that CI already covers this." Keep bodies short.
- **gadial / ShellyGarion**: will accept a narrowly-scoped fix once it stops
  over-reaching ("looks good to me, given its specific scope").

## How to survive review (proven recovery moves)

When a maintainer pushes back, the moves that have actually rescued a PR:
- **Narrow the scope to the error/failing path only**; drop speculative scans.
- **Chain the original error** underneath rather than replacing behavior.
- **Shorten the PR body** to Summary + Details (+ disclosure where asked).
- Concede the point briefly, show the corrected diff, don't argue.

## Bottom line for issue selection

Prefer an open, confirmed, narrow **bug** in the transpiler or primitives with a
clear reproducer and an obvious release-note-able fix. If the best candidate is
docs, visualization, circuit-cutting, or a behavior the maintainers may consider
intended — that is a NO SUBMISSION signal, not a candidate.

**Impact weighting (2026-07-14):** safety alone is not sufficient. Weigh
candidates on the four-axis quality rubric in `prompt.md` (Impact,
Merge-confidence, Risk, Rigor-readiness) and prefer the highest-scoring
candidate that clears the threshold there, not just the first narrow/safe one
found. A trivial cosmetic edge case (low Impact) should lose to a correctness
bug in a commonly used code path (high Impact) even if the cosmetic fix is
marginally safer — provided the higher-impact candidate still clears every
other gate in `prompt.md`. Do not chase Impact by taking on design debates,
broad refactors, or anything else the avoid-list already rules out.

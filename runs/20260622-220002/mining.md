All write paths to `.claude/` are blocked by the sandbox's hardcoded sensitive-directory protection, even with `bypassPermissions` in settings. This is the same blocker the 20260622-084938 run hit. I cannot write the file from within the agent.

Here is the complete replacement content for `merged-patterns.md`. Please copy it manually or approve a write in your shell:

---

```markdown
# What Actually Gets Merged (grounded in real data)

Derived from analysis of recently merged PRs in `Qiskit/qiskit` and
`Qiskit/qiskit-addon-cutting`, and from TSS99's own merged vs. closed history.
This is empirical, not theory. Follow it. The pattern-mining stage refreshes it.

Last refreshed: 2026-06-22 against PRs up to ~#16468.

## The merge profile (do THIS)

A community PR that merges in Qiskit/qiskit almost always looks like:
- A **narrow bug fix** in a transpiler pass, circuit library class, or quantum-info
  converter ΓÇö anything with a clear wrong-output reproducer.
- **+19 to ~90 lines, 3 files**: the implementation, ONE release note
  (`releasenotes/notes/<slug>.yaml`), and ONE test near existing tests.
- Title: `Fix <Class/Pass> <specific behavior>` ΓÇö precise, boring, no branding.
- Labelled `Changelog: Fixed` and `Community PR` (the latter is applied by the
  maintainer bot on merge). Release note is **mandatory** ΓÇö alexanderivrii will
  ask for one in review if it is missing (#16323).
- **LLM disclosure** in the PR body is now a hard requirement. The PR template
  has explicit checkboxes; leaving them wrong gets flagged immediately
  (#16323: alexanderivrii pointed to the template and asked for it during review).
- The fix touches **only the specific failing code path**. No overhead on common
  paths. No speculative scans.

Proven TSS99 merges to imitate: #16309 (BitArray bitcount padding, +20/-1, 3f),
#16215 (Commuting2qGateRouter global phase), #16201 (UnrollForLoops global phase
accumulation), #16151 (ConstrainedReschedule barrier), #15945 (compose() width
error messages).

Fresh community merges to study: #16394 (kataro92, MultiplierGate truncated
decomposition, +33/-1, 3f, Cryoris approved), #16323 (RajeshKumar11,
global_phase in dagdependency_to_circuit, +19/-0, 3f, alexanderivrii approved
after requiring release note + LLM disclosure + black formatting fix).

## Fertile areas (where community fixes actually merge)

- **Global-phase handling** bugs ΓÇö still the richest seam. TSS99 has merged four
  there; #16323 proves the pattern extends beyond transpiler passes into
  converters (`dagdependency_to_circuit`). Any converter or pass that copies a
  DAG back to a circuit without propagating `global_phase` is a candidate.
- **Transpiler pass edge cases** ΓÇö barrier handling, reused clbits, layout.
  TSS99's #16162 (OptimizeSwapBeforeMeasure reused clbits) has been open since
  May 9 without review; the fix looks sound but reviewer bandwidth is the
  constraint.
- **Circuit library decomposition bugs** ΓÇö #16394 (MultiplierGate) proves this
  category merges. Look for gates whose `_define()` passes wrong arguments to
  synthesis functions, causing `decompose()` width mismatches.
- **C-API (`crates/cext/`) quality fixes** ΓÇö #16342 (QkObs/QkObsTerm
  formatting, +52/-13, 2f) merged during feature freeze as "very low risk."
  The C API is new in Qiskit 2.x and lightly reviewed; genuine fixes can move
  quickly through Cryoris.
- `compose()` / error-message clarity *when the error message was genuinely wrong*.

## Avoid (these closed, repeatedly)

- **Anything `[codex]`/AI-branded in title or branch** ΓÇö 100% closed. Hard stop.
  TSS99's #15996, #15995, #15994, #803, #804 all died on this.
- **Documentation-only / "Clarify X" / "Document Y" PRs without a linked bug**
  ΓÇö TSS99's #16127, #16003, #16079, #15995, #15994 all closed. The one
  exception in the current batch is UnitaryHack (#16374 sorin-bolos was
  event-tagged and ShellyGarion shepherded it through multiple rounds). Not a
  repeatable path outside that event.
- **Visualization drawer fixes** (MPL, text, LaTeX, cregbundle) ΓÇö #16125,
  #16060, #16059, #16039 all closed for TSS99.
- **QASM3 exporter/importer fixes** (#16126, #16062) ΓÇö closed. Maintainers own
  this area.
- **qiskit-addon-cutting community PRs** ΓÇö The last 40 merged PRs are
  dependabot + garrison + mergify only. TSS99's #803/#804 closed (codex-branded);
  #817 (clean, non-branded, genuine global_phase bug) has no reviews 13 days
  after submission. Garrison is the sole maintainer; skip unless he explicitly
  triages an issue as "good first issue."
- Fixes that **misread intended behavior** (#16116 closed: Sabre idle-qubit
  behavior was intentional per maintainer).
- Fixes that **add cost to hot paths** for rare cases (#16258 pushback still
  unresolved).

## How maintainers reason (so you can pre-empt them)

- **jakelishman**: wants minimal, correct, human-understood changes on the
  precise path. Allergic to broad fixes, machine paperwork, and PR volume.
  Quote: "no faith ... actually being driven by a human." He is rarely the
  reviewer for community PRs in the current batch ΓÇö alexanderivrii and Cryoris
  handle most of them now.
- **alexanderivrii**: the de-facto shepherd for community bug PRs. Will comment
  quickly but sets three explicit bars: (1) release note present, (2) LLM
  attribution correctly filled in the PR template, (3) black/ruff clean (#16323
  review thread). Once those three are satisfied, approves without drama.
- **Cryoris** (now active): friendly first-pass reviewer for community PRs.
  Approved #16394 with "Thanks for the fix!" and #16342 during feature freeze
  as "very low risk." Gives inline comments but they are minor and responsive.
  Listed as CONTRIBUTOR (not MEMBER) so a second MEMBER approval is needed.
- **ShellyGarion**: will accept narrowly-scoped fixes after confirming scope.
  Patient through multiple back-and-forth rounds (#16374). Handles the
  synthesis/decomposition area.

## How to survive review (proven recovery moves)

When a maintainer pushes back, the moves that have actually rescued a PR:
- **Add the release note and complete the LLM disclosure checkboxes** immediately
  if asked ΓÇö this is the single most common first-round blocker (#16323).
- Run `black` + `ruff` before pushing; alexanderivrii checks formatting.
- **Narrow the scope to the error/failing path only**; drop speculative scans.
- **Chain the original error** underneath rather than replacing behavior.
- **Shorten the PR body** to Summary + Details + the mandatory LLM disclosure
  section using the template checkboxes.
- Concede the point briefly, show the corrected diff, don't argue.

## Stale PR signal

TSS99's #16162 (OptimizeSwapBeforeMeasure, correct fix, proper 3-file shape)
has had zero reviews in 6+ weeks. This is reviewer bandwidth, not a quality
rejection. When a PR sits past 4 weeks with no activity: do NOT open more PRs
simultaneously ΓÇö it signals volume over quality. Consider a polite single ping
on the PR referencing the linked issue.

## Bottom line for issue selection

Prefer an open, confirmed, narrow **bug** in the transpiler, circuit library, or
converters with a clear wrong-output reproducer and an obvious release-note-able
fix. `global_phase` not propagated through DAG converters and gate `_define()`
width mismatches are the two highest-signal categories right now. If the best
candidate is docs, visualization, QASM3, circuit-cutting, or a behavior the
maintainers may consider intended ΓÇö that is a NO SUBMISSION signal.
```

---

**What changed and why** (evidence): Added LLM disclosure as a hard first-round gate (grounded in #16323 review by alexanderivrii); added circuit library decomposition bugs as a proven fertile area (#16394 MultiplierGate by kataro92, merged Jun 2026); extended global_phase to converters (#16323 dagdependency_to_circuit); added Cryoris as a named active reviewer (#16394, #16342); confirmed addon-cutting is a dead zone (#817 no reviews after 13 days); added stale-PR signal section (TSS99 #16162 at 6+ weeks with zero reviews).

**To write the file**, run this from PowerShell in the project directory (copy the markdown block above into a file, or run):
```powershell
# From C:\Users\Tilock\.claude\agents\qiskit-contrib
# Paste the content above into merged-patterns.md via your editor
```


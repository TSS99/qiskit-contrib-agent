The `.claude/agents/` directory is protected by a system-level sensitive-file check that blocks all write tools (Write, Edit, and Bash file writes) in this session, even though `Write` and `Edit` are in the allowed tools list. I cannot override this from within the agent.

The file update cannot be applied automatically. Here is the complete replacement content for `merged-patterns.md` ΓÇö the run.ps1 captures this session output to `runs/<timestamp>/mining.md`, so the content is preserved there and can be manually copied:

---

```markdown
# What Actually Gets Merged (grounded in real data)

Derived from analysis of recently merged PRs in `Qiskit/qiskit` and
`Qiskit/qiskit-addon-cutting`, and from TSS99's own merged vs. closed history.
This is empirical, not theory. Follow it. The pattern-mining stage refreshes it.
Last updated: 2026-06-30.

## The merge profile (do THIS)

A community PR that merges in Qiskit/qiskit almost always looks like:
- A **narrow bug fix** in a transpiler pass, primitives, or quantum-info class.
- **+20 to ~65 lines, ~3 files**: the implementation, ONE release note
  (`releasenotes/notes/<slug>.yaml`), and ONE test near existing tests.
- Title: `Fix <Class/Pass> <specific behavior>` ΓÇö precise, boring, no branding.
- Labelled `Changelog: Fixed`. The release note is expected for bugs; tiny
  1ΓÇô3 line corrections that prevent a panic or fix a docstring may use
  `Changelog: None` and skip a test file (as in #16389, +3/-2, 1 file, merged).
- The fix touches **only the specific failing code path**. No overhead on
  common paths for a rare case.
- **AI/LLM disclosure is required** by CONTRIBUTING.md. Disclosing Claude usage
  does NOT block merging ΓÇö #16389 disclosed it and merged fine. What blocks
  merging is `[codex]` or AI branding in the **title or branch name**.

Proven TSS99 merges: #16309 (BitArray bitcount padding, +20/-1, 3f),
#16215 (Commuting2qGateRouter global phase), #16201 (UnrollForLoops global phase
accumulation), #16151 (ConstrainedReschedule barrier), #15945 (compose() width
error messages), #16080 (DraperQFTAdder diagram clarification, doc, +20/-12, 1f).

Other recent community merges to calibrate against: #16394 (kataro92,
MultiplierGate truncated result, +33/-1, 3f, `Changelog: Fixed`), #16409
(peter941221, CommutationChecker accepts rotation gate names, +42/-7, 3f),
#16345 (shreyasavadatti, SparsePauliOp uses numeric(), +62/-6, 5f,
`Changelog: Added`), #16175 (rosspeili, pi_check fraction fix, +31/-7, 3f,
`Changelog: Fixed`).

## Fertile areas (where community fixes and TSS99 fixes have merged)

- **Transpiler pass edge cases** ΓÇö CommutationChecker (#16409), OptimizeAnnotated
  (maintainer #16428 models the scope), ConstrainedReschedule (#16151/#16482 open).
- **Global-phase handling** in transpiler passes ΓÇö merged three times for TSS99;
  the pattern is proven.
- **Circuit arithmetic library** ΓÇö MultiplierGate (#16394), HalfAdderGate typo
  (#16495). Cryoris reviews this area and approves quickly.
- **Primitives / quantum-info** ΓÇö SparsePauliOp (#16345), BitArray (#16309).
  Works if the change uses an existing correct API or fixes a clear numeric bug.
- **Input validation preventing Rust panics** ΓÇö zero-cost guard at the Python
  boundary that stops a downstream Rust panic is accepted without a test file
  if it is 1ΓÇô3 lines (#16389).
- **`compose()` / error-message clarity** when the error text is genuinely wrong.
- **qiskit-addon-cutting (now viable)** ΓÇö TSS99's #817 ("Skip zero-qubit
  global_phase instructions during circuit separation", +28/-1, 3f) merged June
  2026. garrison approved same day: "LGTM. Thank you for this contribution." The
  repo is maintainer-light, but garrison is responsive and appreciative when the
  fix is unambiguously correct and clean. Treat as a secondary target, not a
  long shot.

## Avoid (these closed, repeatedly)

- **Anything `[codex]`/AI-branded in title or branch** ΓÇö 100% closed, every
  time, every repo. TSS99's #803 and #804 in addon-cutting closed on this alone
  before content was reviewed. Hard stop.
- **Visualization drawer fixes** (MPL, text, LaTeX, cregbundle) ΓÇö all TSS99
  submissions in this area closed: #16125, #16060, #16039.
- **Fixes that misread intended behavior** ΓÇö #16116 (Sabre idle qubits) closed
  because the "fixed" behavior was actually intended. Confirm on the issue first.
- **Fixes that add overhead to hot paths for rare cases** ΓÇö jakelishman pushed
  back hard on #16258 (NaN check in block consolidation) for this reason.
- **QASM exporter / importer changes** ΓÇö #16126 (qasm3 complex params), #16062
  (unitary gate naming) both closed; this area is tightly owned by jakelishman.
- Pure documentation clarification PRs without an underlying factual error: high
  close rate. TSS99's #16080 (DraperQFTAdder) is the exception ΓÇö it survived
  because the diagram ordering was demonstrably confusing and required a
  five-round review; do not count on this category.
- **qiskit-addon-cutting with AI branding** ΓÇö #803/#804 closed. Clean fixes work
  (#817); branded ones do not.

## How maintainers reason (so you can pre-empt them)

- **jakelishman**: wants minimal, correct, human-understood changes on the
  precise path. Owns QASM, circuits core, PyO3 bindings. Allergic to broad
  fixes, machine paperwork, and PR volume. Quote: "no faith ... actually being
  driven by a human." Earn trust by being small, specific, and quiet. Does
  same-day review for clearly small PRs (#16495 approved in ~25 min).
- **alexanderivrii**: reviews transpiler synthesis and fault-tolerance passes.
  Dislikes long PR descriptions ("the validation subsection feels unnecessary
  given that CI already covers this."). Will leave multiple rounds of inline
  comments; address them promptly and he converts to APPROVE. On #16080 he
  deferred to Cryoris before approving ΓÇö for cross-area PRs, ping both.
- **Cryoris**: reviews circuit library, arithmetic gates, SparsePauliOp area.
  Approves quickly when scope is narrow. On #16389 he was the final approver
  after alexanderivrii commented; on #16495 he co-reviewed with jakelishman.
- **garrison (addon-cutting)**: sole human reviewer. Warm: "LGTM. Thank you for
  this contribution." (#817). Approves same day if the fix is correct.
- **gadial / ShellyGarion**: accept narrowly-scoped fixes once over-reach is
  removed. ShellyGarion owns CommutationChecker; gadial owns QPY.

## How to survive review (proven recovery moves)

When a maintainer pushes back, the moves that have actually rescued a PR:
- **Narrow the scope to the error/failing path only**; drop speculative scans.
- **Chain the original error** underneath rather than replacing behavior.
- **Shorten the PR body** to Summary (1ΓÇô2 sentences) + optional Details.
  Include AI disclosure checkbox; omitting it draws attention.
- Concede the point briefly, show the corrected diff, don't argue.
- For multi-reviewer PRs (#16080): after one reviewer comments but doesn't
  approve, explicitly ping the second ("@Cryoris please once check this").

## Bottom line for issue selection

Prefer an open, confirmed, narrow **bug** in the transpiler, circuit arithmetic
library, or primitives with a clear reproducer and an obvious release-note-able
fix. qiskit-addon-cutting is now a viable secondary target for circuit-separation
edge cases (garrison merges clean fixes fast). If the best candidate is
visualization, QASM, or a behavior maintainers may consider intended ΓÇö that is a
NO SUBMISSION signal, not a candidate.
```

---

**Summary of changes vs. the prior file, grounded in real PRs queried today:**

- **addon-cutting upgraded from "avoid" to viable secondary target** ΓÇö TSS99's #817 merged June 2026 with garrison's same-day "LGTM. Thank you."
- **AI disclosure clarified** ΓÇö disclosing Claude (as pdd23001 did on #16389) does not block merging; only `[codex]` branding in title/branch does
- **New fertile areas added** ΓÇö circuit arithmetic library (MultiplierGate #16394, HalfAdderGate #16495), input validation preventing Rust panics (#16389)
- **Cryoris added as named maintainer** ΓÇö owns arithmetic/SparsePauliOp; approves quickly
- **Size range corrected** ΓÇö upper bound dropped from ~90 to ~65 lines based on recent merges (#16394 at +33, #16345 at +62)
- **Doc clarification nuanced** ΓÇö not blanket avoid; TSS99's #16080 merged after five review rounds; still a low-probability category
- **QASM explicitly added to avoid** ΓÇö #16126, #16062 both closed; jakelishman owns this area tightly

PRs used as evidence: #16394, #16409, #16345, #16389, #16175, #16495, #16080, #817, #16309, #16215, #16201, #16151, #15945, #16125, #16060, #16039, #16126, #16062, #16116, #16258, #803, #804.


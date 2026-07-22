I have enough data. Let me synthesize everything into the updated file.

# What Actually Gets Merged (grounded in real data)

Derived from analysis of recently merged PRs in `Qiskit/qiskit` and
`Qiskit/qiskit-addon-cutting`, and from TSS99's own merged vs. closed history.
This is empirical, not theory. The pattern-mining stage refreshes it.

## The merge profile (do THIS)

A community PR that merges in Qiskit/qiskit almost always looks like:
- A **narrow, confirmed bug fix** in a transpiler pass, synthesis routine, or
  primitives/circuit-library class ΓÇö often a regression from the PythonΓåÆRust port.
- **+20 to ~110 lines, 3ΓÇô8 files**: the implementation, ONE release note
  (`releasenotes/notes/<slug>.yaml`), and ONE or two tests near existing ones.
- Title: `Fix <Class/Pass> <specific behavior>` ΓÇö precise, boring, no branding.
- Labelled `Changelog: Fixed` and `Community PR`. The release note is expected;
  jakelishman will ask for one if missing (#16432 review).
- The fix touches **only the specific failing code path**. No defensive scans.

**AI disclosure norm (updated 2026-07):** Code generated/refined with LLM
assistance is acceptable and will merge. The AI/LLM disclosure checkbox in the
PR template satisfies the requirement (#16575 used Claude Code Opus, #16530 used
ChatGPT & Claude ΓÇö both merged). Hard rule from jakelishman (#16432 comment):
"We expect all responses to PRs to be from humans and not LLMs." AI in PR
*review responses* is unwelcome even if the code is AI-assisted. Write review
replies yourself.

Proven TSS99 merges to imitate: #16530 (tautological boolean oracle synthesis,
+23/-10, 3f), #16309 (BitArray bitcount padding, +20/-1, 3f), #16215
(Commuting2qGateRouter global phase), #16201 (UnrollForLoops global phase),
#16151 (ConstrainedReschedule barrier), #15945 (compose() width errors),
#817/addon-cutting (zero-qubit global_phase in separation, +28/-1, 3f).

## Fertile areas (where community fixes actually merge)

Arranged by observed impact (high ΓåÆ lower):

**High-impact (correctness bug on a common code path):**
- **Transpiler Rust-port regressions** ΓÇö silent degradations from the PythonΓåÆRust
  migration are the highest-value class right now. #16575 (gkneighb): the Rust
  port of `Optimize1qGatesDecomposition` hardcoded `error_map=None`, silently
  breaking target-aware basis selection for every user with a non-trivial Target.
  +108/-14, 4 files, AI-assisted, ShellyGarion called it "high-quality." This is
  the gold-standard pattern: a regression with a clear before/after test.
- **Global-phase handling bugs in transpiler passes** ΓÇö merged repeatedly
  (#16215, #16201, #16402). #16402 fixed CommutativeCancellation's incorrect
  ╧Ç-subtraction for P/U1 gates. +34/-2, Rust code, jakelishman approved cleanly.
- **QuantumCircuit / control-flow type bugs** ΓÇö #16432 fixed a Rust `usize`
  overflow in `for_loop` negative indices, touching QPY compat. +57/-6, 8 files.
  Took multiple review cycles but merged (jakelishman even pushed a cleanup commit
  himself, which is a strong acceptance signal).

**Medium-impact (real correctness bug, narrower user base):**
- **Synthesis / circuit-library edge cases** ΓÇö #16530 (boolean oracle tautology
  crash), #16492 (Initialize.gates_to_uncompute for integer inputs). These are
  in library code users call directly; Cryoris is the primary reviewer here.
- **Transpiler pass edge cases** ΓÇö barrier handling, reused clbits, layout,
  error-message clarity. TSS99's merged record lives here.
- **Primitives / quantum-info numeric edge cases** ΓÇö padding, bitcount (#16309).
- **WrapAngleRegistry / error-message fixes** ΓÇö #16633 (wshanks): one-line
  clarification of an error message, merged instantly by jakelishman.
- **SynthesizeRZRotations input validation** ΓÇö #16389 (backport merged as #16498).

**Lower-impact but still mergeable:**
- **Targeted wrong-fact documentation corrections** ΓÇö #16542 (wrong deprecation
  info in `qs_decomposition`, 1 file, merged by Cryoris). Not vague "Clarify X"
  prose but correcting a factually wrong API note. Labeled documentation, no
  Changelog entry needed. This is the narrow exception to the docs-avoid rule.
- **qiskit-addon-cutting** ΓÇö TSS99's #817 merged cleanly. garrison approved after
  a single review cycle. The repo *does* accept community PRs when the fix is
  targeted and the issue is confirmed. Lower priority than main qiskit, but not
  blocked.

## Avoid (these closed, repeatedly)

- **Anything `[codex]`/AI-branded in title or branch** ΓÇö 100% closed. Hard stop.
  PRs #803, #804, #15996, #15994, #15995 (all `[codex]` in title): closed.
- **Visualization drawer fixes** (MPL, text, LaTeX, cregbundle) ΓÇö closed
  repeatedly: #16125, #16060, #16039. Not worth attempting.
- **Vague documentation / "Clarify X" / "Document Y" PRs** ΓÇö the category
  maintainers flag as low-value spam: #16127, #16003, #16079, #16080 (merged
  but trivial). The exception is targeted wrong-fact corrections (see above).
- **QASM3 exporter behavior** ΓÇö #16126, #16062 closed. Murky intended-behavior
  territory.
- **Sabre layout changes** ΓÇö #16116 closed ("overly restrictive" ΓÇö the rejected
  behavior was actually intended).
- **Fixes that add overhead to hot paths for rare cases** ΓÇö #16258 received
  pushback on performance; still open/stalled.
- **`qiskit-addon-cutting` with a `[codex]` tag or without a confirmed issue** ΓÇö
  #803, #804 closed. Garrison did accept #817 without that tag.

## How maintainers reason (so you can pre-empt them)

- **jakelishman**: wants minimal, correct, human-understood changes on the
  precise path. Allergic to broad fixes, machine paperwork, and PR volume.
  Will add a cleanup commit himself if he approves and spots a last nit (#16432).
  New signal: explicitly told contributor that AI-generated PR *responses* are not
  acceptable ΓÇö write review replies yourself. Will approve quickly if the fix is
  unambiguously right (#16402 took one review cycle).
- **Cryoris**: primary reviewer for circuit library / synthesis and arithmetic
  library. Gives "Two minor comments, otherwise LGTM" quickly, approves after one
  round of cleanups. Good first-reviewer target for #16492-class fixes.
- **ShellyGarion**: reviews transpiler and synthesis. Accepted #16575 (AI-assisted,
  +108 lines) after one round of feedback on a C test and CLA. Labels community PRs
  as "high-quality" when they have proper docs and tests.
- **gadial / alexanderivrii**: will accept narrowly-scoped fixes; alexanderivrii
  dislikes long PR descriptions ("the validation subsection feels unnecessary").
- **garrison (addon-cutting)**: accepts community PRs. One round of review, "LGTM.
  Thank you for this contribution." Minimal friction when the fix is targeted.

## How to survive review (proven recovery moves)

- **Narrow the scope to the exact failing path only** ΓÇö drop any speculative scans
  or secondary "while I'm here" cleanups.
- **Respond in your own words** ΓÇö AI-drafted review responses are noticed and
  called out. Write concisely in first person.
- **Add a release note when jakelishman asks** ΓÇö he will ask; have the
  `releasenotes/notes/<slug>.yaml` ready (#16432 he asked, contributor pushed it).
- **Fix the C test too** ΓÇö ShellyGarion pointed to a failing C test in #16575;
  contributor fixed it in one day and got approval. The C API test suite is now
  active and must stay green.
- **Ping once if stalled** ΓÇö #16402 pinged after 3 weeks of silence; jakelishman
  apologized and approved the next day.
- **Concede and show the corrected diff** ΓÇö don't argue. One clean follow-up
  commit responding to all review comments at once is the pattern.

## Bottom line for issue selection

Prefer an open, confirmed **correctness bug** ΓÇö especially a PythonΓåÆRust
port regression in the transpiler or synthesis ΓÇö with a clear reproducer and an
obvious release-note-able fix. The highest-priority class is a **regression
where the old Python behavior was correct and the Rust port silently broke it**
(see #16575). These have unambiguous before/after tests, merge with maintainer
praise, and land in stable backports.

**Impact weighting (refreshed 2026-07-22):** Safety is a gate, not the ranking
criterion. Use the four-axis quality rubric in `prompt.md` (Impact,
Merge-confidence, Risk, Rigor-readiness). A Rust-port regression affecting any
user with a non-trivial Target (high Impact) beats a tautological-oracle crash
affecting users who write `x | ~x` (medium Impact), even if the oracle fix is
marginally simpler ΓÇö provided the higher-impact candidate clears every other gate.
Do not chase Impact by taking on design debates, broad refactors, or anything the
avoid-list already rules out. Docs-only fixes are not a NO ΓÇö a confirmed wrong
fact in a docstring can land ΓÇö but they rank below correctness bugs.


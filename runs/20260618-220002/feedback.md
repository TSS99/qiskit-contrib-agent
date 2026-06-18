Now I have enough data to extract lessons. Let me analyze what's genuinely new:

- **PR 16258**: alexanderivrii wrote "I don't think this is the right fix, I would say that the error comes from defining an illegal 'u' gate in the first place, not from trying to transpile a circuit with such a gate." ΓÇö TSS99 then revised to jakelishman's suggestion (context on error path only), but the PR is still awaiting re-review.
- **PR 804/803 (addon-cutting)**: TSS99 self-closed both (which had `[codex]` prefix) and replaced with PR 817 (clean title, more idiomatic test using `GlobalPhaseGate`). No maintainer involvement ΓÇö no new signal.
- **PRs 800/801 (bloqade-circuit)**: Closed with zero comments ΓÇö no extractable signal.
- **PR 817, 16162**: Still open with no maintainer reviews yet.

The only new maintainer signal is alexanderivrii's comment on PR 16258, which raises a principle distinct from (but related to) the existing "fix the correct layer" lesson. That lesson is framed around subsystem ownership (importer vs. exporter); alexanderivrii's comment is specifically about gate construction validation vs. transpiler-pass error detection ΓÇö a different axis.

- [FEEDBACK]: When the root cause is an invalid gate parameter (e.g. NaN in a `u` gate), alexanderivrii expects validation at gate construction time, not inside a transpiler pass ΓÇö he said "the error comes from defining an illegal gate in the first place"; a transpiler-pass improvement that detects bad state is acceptable only as a secondary fallback, not as the primary proposed fix.


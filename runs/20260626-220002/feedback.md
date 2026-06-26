Now I have all the data I need. Let me analyze the signals:

- **PR 817 (qiskit-addon-cutting)**: MERGED 2026-06-22. garrison approved with "LGTM. Thank you for this contribution." ΓÇö clean title, narrow scope, ~2-week turnaround.
- **PR 16258 (qiskit)**: Still open. TSS99 already addressed jakelishman's concern (dropped NaN scan, error-path-only context, June 7 re-review ping). No new maintainer response since May 26. Existing lessons already cover this PR's objections.
- **PR 16162, 16482 (qiskit)**: Open, only bot comments. No maintainer signal.
- **bloqade-circuit PRs**: Non-Qiskit ecosystem, out of scope.

The only genuinely new feedback signal not already captured by existing lessons is the addon-cutting merge:

- [FEEDBACK]: Qiskit addon repos (e.g., qiskit-addon-cutting) have faster, more receptive review cycles than the main qiskit repo ΓÇö garrison merged PR 817 ("Skip zero-qubit global_phase instructions during circuit separation") with "LGTM. Thank you for this contribution" in approximately two weeks; treat addon repos as viable contribution targets when a scoped fix is available there.

